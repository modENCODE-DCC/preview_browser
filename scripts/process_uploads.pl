#!/usr/bin/perl -w 
# This script processes unreleased uploads
# to create a preview database and config for WIG and GFF3 files
use strict;

# Trick to get the current working directory and include ./lib 
# before we get started with the rest of the code
my $root_dir;
BEGIN {
  $root_dir = $0;
  $root_dir =~ s/[^\/]*$//;
  $root_dir = "./" unless $root_dir =~ /\//;
  push @INC, $root_dir . "/lib";
}
#use Cluster;
use ConfigSet;
use MyConstants;
use Data::Dumper;
use File::Spec;
use LWP::UserAgent;
use CGI  qw/escape unescape/;

my $debug                = MyConstants::DEBUG;
my $where                = MyConstants::WHERE;
my $submission_key_url   = MyConstants::SUBMISSION_KEY_URL;
my %organism             = MyConstants::ORG;
my %lab_color            = MyConstants::LABCOLOR;
my $upload_dir           = MyConstants::UPLOAD_DIR;
my $data_dir_suffix      = MyConstants::DATA_DIR_SUFFIX;
my $browser_root_dir     = MyConstants::BROWSER_ROOT;
my $browser_conf_species = MyConstants::BROWSER_CONF_USES_SPECIES;
my $browser_dir_pre_proj = MyConstants::BROWSER_DIR_BEFORE_PROJECT_ID;
my $browser_dir_suffix   = MyConstants::BROWSER_DIR_SUFFIX;
my %make_summary         = map {$_ => 1}  MyConstants::WIG;
my %refseq_OK            = map {$_ => 1}  MyConstants::REFSEQ;

# If this script is not run on the destination server
# indicate the system path that will be used there
my $final_where  = MyConstants::DESTINATION_DIR;
$final_where = ($final_where =~ /^\// ? $final_where : $root_dir.$final_where);
$final_where = File::Spec->rel2abs($final_where);

# The list of project numbers
my @projects;

# link project numbers to labs and desciptions
# need to automate creation of key.txt file (is it automated yet?)
$where = ($where =~ /^\// ? $where : $root_dir.$where);
$where = File::Spec->rel2abs($where);
my $submission_key_file =  File::Spec->catfile($where, "submission_key.txt");
if ($submission_key_url) {
  my $useragent = new LWP::UserAgent();
  my $res = $useragent->mirror($submission_key_url, $submission_key_file);
  if (!$res->is_success) {
    warn "Unable to mirror submission key URL to local file: $!";
  }
}

open IN, $submission_key_file or die "Couldn't open submission list file: $!";

my %project;
while (<IN>) {
  chomp;
  $_ or next;
  my ($p,$deprecated, $deprecated_by, $url, $desc, $lab, $status) = split "\t";
  next if $status =~ /^released$/;
  $lab =~ s/,.+//;
  $desc =~ s/$lab[-_ ]*//i;
  $project{$p}{group} = $lab  || 'unknown submitting group';
  $project{$p}{desc}  = $desc || 'unknown submission type'; 
}

# if have command-line args, just run
if (@ARGV) {
    @projects = @ARGV;
}
# otherwise, we are in deployment mode
else {
#    my $outbase = "/datafc/stein/mckays/preview_data";
#    my $cluster = Cluster->new( -jobs        => 1,
#				-executable  => "$where/scripts/process_uploads.pl",
#				-runfile     => 'uploads.sh',
#				-log         => "$outbase/log");
    
#    my @uploads = sort {$a<=>$b} keys %project; 
#    my @to_run;
#    for my $u (@uploads) {
#	my $done = -e "$outbase/browser/fly/$u.conf" || -e "$outbase/browser/worm/$u.conf";
#	print "Skipping $u, it is done...\n" and next if $done;
#	push @to_run, $u;
#	system "rm -fr $outbase/browser/$u" if -d "$outbase/browser/$u";
#	print "$u\n";
#    }
#    print "I will run ",scalar(@to_run)," of ",scalar(@uploads), " jobs\n";
#    $cluster->cluster(@to_run);    
#    exit;
  print STDERR "Showing all unreleased submissions:\n";
  print STDERR join("\n", map { "$_\t" . $project{$_}->{'group'} . "\t" . $project{$_}->{'desc'} } sort { $a <=> $b } keys(%project));
  print STDERR "\n\n";
  die "Usage: ./process_uploads.pl uploadnum1 uploadnum2 ... uploadnumn\n";
}

my $force = 1;

if ($upload_dir) {
  if ((-d $where) && !(-d File::Spec->catfile($where, $upload_dir))) {
    mkdir File::Spec->catfile($where, $upload_dir) or warn "could not create ".File::Spec->catfile($where, $upload_dir). " $!";
  }
}
my $scripts = File::Spec->rel2abs($root_dir);


# Bit of a sanity check: are they unpacked directories?
PROJECT: for my $d (@projects) {
  my $project_dir = File::Spec->catfile($where, $upload_dir, $d, $data_dir_suffix);
  if (!-d $project_dir) {
    warn "$project_dir does not exist or is not a directory!";
    next;
  }

  my $desc = $project{$d}{desc};
  my $lab  = $project{$d}{group};

  # We don't know which species yet
  my $species;

  # Recurse through the project directory and
  # find anything that is a WIG or a GFF file
  # Other formats, get lost!
  my $files = [];
  recursedir($project_dir, $files);
  
  my ($readme) = grep {/README/ || /idf/i} @$files;
  my $readme_text = prepare_citation($readme,$desc,$lab)
      if $readme && $desc && $lab;
  $readme_text ||= $desc || $lab;
  #print STDERR "README text\n$readme_text\n" if $debug;

  my ($bdir, $final_bdir);
  if ($browser_dir_pre_proj) {
    $bdir       = File::Spec->catfile($browser_root_dir, $d, $browser_dir_suffix);
    $final_bdir = File::Spec->catfile($final_where, $d, $browser_dir_suffix);
  } else {
    $bdir       = File::Spec->catfile($browser_root_dir, $browser_dir_suffix, $d);
    $final_bdir = File::Spec->catfile($final_where, $browser_dir_suffix, $d);
  }
  #my $bdone   = $where . "/browser/$d.txt";

  # allow parallel processing
  #next if -e $bdone;
  #system "touch $bdone";

  print STDERR "Working on submission $d...\n" if $debug;

  my @my_files = grep {!/README|idf/} @$files;
  if (@my_files) {
    my @gff_to_load;

    # partition into gff and WIG files, give up if there are neither
    my (@gff,@wig);
    next if -d $bdir && !$force;
    if ($force && -d $bdir) {
      `rm -fr $bdir`;
    }
    system("mkdir -p '$bdir'") == 0 or die $!;

    # get the wiggle and gff files only
    find_wig_and_gff(\@gff,\@wig,$files);

    # GIve up now if there aren't any
    if ( (@wig + @gff) == 0 ) {
	print STDERR "\n\nSubmission $d had no GFF or WIG files, what am I suppposed to do with it?\n\n";
	next PROJECT;
    }

    my $db_dir = "$bdir/db";
    mkdir $db_dir or die $! unless -d $db_dir;


    # save the paths to all raw data files
    open DT, ">$bdir/data_files.txt" or die $!;
    print DT join("\n","Raw data files:", map {$where . "/uploads/$_"} grep {!/(txt|cel|pair)$/i} @$files), "\n";

    # This is where the berekeleydb will be stored  
    system "rm -fr $bdir/db" if -e "$bdir/db";
    `mkdir -m 777 $bdir/db`;
    die "Some sort of problem with $bdir/db" unless -d "$bdir/db";

    my ($gff_dir,$wig_dir,$wib_dir);

    # get ready if we have GFF and/or WIG
    $gff_dir = "$bdir/gff";
    mkdir $gff_dir unless -d $gff_dir;

    my (%class,%seen,$summary,$peaks);
    print "\n\n";
    print "Processing data files:\n";

    # Got GFF?
    for (@gff) {
      my $gff_file = $_;
      print STDERR "  Processing GFF file: $_...\n" if $debug;
      my ($volume,$path,$file) = File::Spec->splitpath($_);
      my $outfile = "$gff_dir/$file.gz";

      open GFFIN, ($file =~ /gz$/ ? "gunzip -c '$_' |" : $_) or die $!;
      open GFFOUT, "| gzip -c >'$outfile'";
      print GFFOUT "##gff-version 3\n";

      # For now, we WILL NOT index subfeatures
      print GFFOUT "##index-subfeatures 0\n";
    
      my ($are_peaks,$gfflines);
      while (<GFFIN>) {
	my $isa_peak;

	# skip directives, we have our own
	next if /^\#/;

        # Curse you, UCSC!
	s/^chr//i;

        # Features with no coords, what's the point?
	my ($ref,$src,$met,$start,$end) = (split)[0..4];
	next unless $start && $end && $met;

	# skip hit targets and other non-displayed features
        # with non-chromosome ref. sequences
	next unless $refseq_OK{$ref};

        # believe it or not, this is necessary
        # and junk manages to slip through even after this
        next unless are_we_sure_this_is_good_gff($_);

	# no kids allowed; just index top-level feats
	my $child = /Parent=/;

        # Try to guess the species
        unless ($species) {
	  $species = guess_species($lab,$ref);
	}

	# If this is a wiggle peak sort of thing, go to summary mode
        if ($make_summary{$met}) {
	  print STDERR "\nType '$met' is likely a peak feature, we will make a wiggle summary track for this.\n\n" 
	      if $debug && !$seen{$met}++;
	  $isa_peak  = $are_peaks = 1;
	}
	else {
	  push @{$class{lookup($met)}}, $met unless $seen{$met}++ || $child;
	}
 	if ($desc) {
	  $desc = escape($project{$d}{desc});

	  # replace source tags but avoid regex here due to lots of non-word chars
	  my @gff_line = split "\t";
	  $gff_line[1] = $desc;
	  $_ = join("\t",@gff_line);

	  $desc = unescape($desc);
	}

	print GFFOUT $_;
	$gfflines++ unless $isa_peak;

      }

      close GFFIN;
      close GFFOUT;
      
      print STDERR "    These are the data classes in this GFF:\n      ". join("      \n", map { "$_: " . join(", ", @{$class{$_}}) } keys(%class)) . "\n\n" if $debug;

      # Really big GFF files get a wiggle_box summary for no extra charge
      if ($are_peaks || $gfflines > 10){#0000) {
	  $are_peaks ? $peaks++ : $summary++;
	  print STDERR "      Working on summary (wiggle box) tracks...\n" if $debug && $are_peaks;
	  print STDERR "      This is a really big GFF file, I am making summary (wiggle box) tracks...\n" if $debug && !$are_peaks;
	  mkdir File::Spec->catfile($bdir, "wib") unless -d File::Spec->catfile($bdir, "wib");
	  my $file_type = $are_peaks ? 'peaks' : 'summary';
	  my $cmd = File::Spec->catfile($scripts, "gff2wig_summary.pl") . " '$outfile' '" . File::Spec->catfile($bdir, "wib") . "' $file_type";
	  print STDERR "      Executing gff2wig_summary.pl...\n\n" if $debug;
          print STDERR "      vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv\n" if $debug;
          system $cmd;
          print STDERR "\n      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n" if $debug;
      
	  if (!$gfflines) {
	      unlink $outfile;
	  }
	  else {
	      push @gff_to_load, $outfile;
	  }
	  $outfile =~ s/(\S+)\.gff/${1}_$file_type\.gff/;
	  push @gff_to_load, $outfile;
      }      
      else {
	  push @gff_to_load, $outfile;
      }
  }
    # Got WIG?
    for (@wig) {
      my $wig_file = $_;
      print STDERR "  Processing WIG file $_...\n" if $debug;
      my ($volume,$path,$file) = File::Spec->splitpath($_);
      $wib_dir ||= "$bdir/wib";
      mkdir $wib_dir unless -d $wib_dir;

      # now we make the wiggle binary
      (my $wigout = "$gff_dir/$file")  =~ s/\.wig(\.gz)?/_wiggle\.gff\.gz/;
      (my $wigname = $file) =~ s/\.wig\S+$//; 
      my $display_name = escape($wigname);

      print STDERR "  Making the binary file now...\n" if $debug;
      my $cmd = "wiggle2gff3.pl --source '$wigname' --path '$wib_dir' '$wig_file' |sed 's/chr//' | perl -pe 's/Name=[^;]+/Name=$display_name/' |gzip -c >'$wigout'";
      print STDERR "\n  Executing wiggle2gff3.pl...\n" if $debug;
      print STDERR "    vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv\n" if $debug;
      system $cmd;
      print STDERR "    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n" if $debug;
      print STDERR "  Done making binary: $wigout is saved\n" if $debug;
      push @gff_to_load, $wigout;
      
    }

    print "Done processing data files.\n\n";

    if (@gff_to_load) {
      # fix local paths
      if ($where ne $final_where) {
	    print STDERR "  Fixing local path \"$where\" -> \"$final_where\" in GFF files pointing at WIGs.\n" if $debug;
            my $gff_dir = File::Spec->catfile($bdir, "gff");
	    system "gunzip " . File::Spec->catfile($gff_dir, "*gz");
	    system "perl -i -pe 's|wigfile=$where|wigfile=$final_where|' " . File::Spec->catfile($gff_dir, "*");
	    system "gzip " . File::Spec->catfile($gff_dir, "*");
	}

      print STDERR "GFF files for loading:\n  " . (join("\n  ", @gff_to_load)) . "\n" if $debug;

      my @non_summary = grep {!/_summary/ && !/_wiggle/ && !/_peak/} @gff_to_load;
      my @summary     = grep {/_summary/} @gff_to_load;
      my @wiggle      = grep {/_wiggle/}  @gff_to_load;
      my @peak        = grep {/_peak/}  @gff_to_load;

      # make an audit trail
      if (@non_summary) {
        print DT "\nRegular GFF:\n",join("\n",@non_summary), "\n";
      }
      if (@summary) {
	print DT "\nWiggle box summary GFF:\n",join("\n",@summary), "\n";
      }
      if (@wiggle) {
        print DT "\nWiggle GFF:\n",join("\n",@wiggle), "\n";
      }
      if (@peak) {
	print DT "\nPeak Wiggle GFF:\n",join("\n",@peak), "\n";
      }

      if (!$species) {
	  print STDERR "\n  I still don't know the species for $lab, I will try to guess from the final gff data\n" if $debug;
	  OUTER: for my $f (@gff_to_load) {
	      chomp(my @refs = `zcat $f |cut -f1 |sort -u`);
	      for my $r (@refs) {
		  $species = guess_species($lab,$r);
		  last OUTER if $species;
	      }
	  }
      }

      # Now we load the actual Bio::DB::Seqfeature::Store database
      my $cmd = "nice -10 bp_seqfeature_load.pl -c -d '$db_dir' -f -a berkeleydb " . join(' ',map {"'$_'"} @gff_to_load);
      print STDERR "\n  I will now load the GFF files into the database...\n" if $debug;
      print STDERR "\n    Executing bp_seqfeature_load.pl...\n" if $debug;
      print STDERR "    vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv\n" if $debug;
      system $cmd;
      print STDERR "    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n" if $debug;
      print STDERR "  Done loading!\n\n" if $debug;
    }
    else {
      next;
    }

    if (!$species && $readme_text) {
      $species = 'fly'  if $readme_text =~ /melanogaster/;
      $species = 'worm' if $readme_text =~ /elegans/;
    }
    $species ||= 'unknown';

    system("chmod -R a+rX $bdir") == 0 or warn "Couldn't change read permissions on $bdir: $!"; 
    system("chmod -R ug+w $bdir") == 0 or warn "Couldn't change write permissions on $bdir: $!"; 

    print STDERR "Writing configuration file.\n" if $debug;
    my $conf_dir;
    if ($browser_dir_pre_proj) {
      $conf_dir   = ($browser_conf_species ? File::Spec->catfile($bdir, $species) : $bdir);
    } else {
      $conf_dir   = ($browser_conf_species ? File::Spec->catfile($browser_root_dir, $browser_dir_suffix, $species) : $browser_root_dir);
    }
    mkdir $conf_dir unless -d $conf_dir;
    open CONF, ">", File::Spec->catfile($conf_dir, "$d.conf");

    print CONF 
	"[$d:database]\n",
	"db_adaptor    = Bio::DB::SeqFeature::Store\n",
	"db_args       = -adaptor berkeleydb\n",
	"                -dsn    " . File::Spec->catfile($final_bdir, "db") . "\n\n";

    if ($peaks) {
	my $conf = get_config('wiggle_discrete',$lab);
	print CONF "[${d}_PEAKS]\n";
	print CONF sprintf("%-20s","feature")."= summary\n";
	print CONF sprintf("%-20s","database")."= $d\n";
	print CONF sprintf("%-20s","name")."= sub{shift->source_tag}\n";
	print CONF sprintf("%-20s","label")."= 1\n";
	print CONF sprintf("%-20s","key")."= $d $desc\n";
	print CONF sprintf("%-20s","category")."= modENCODE Preview Tracks:$lab:computed peak tracks\n";
	print CONF $conf;
	print CONF sprintf("%-20s",'config set')."= wiggle_discrete\n";
	print CONF sprintf("%-20s",'citation')."= $readme_text\n\n";
    }
    if ($summary) {
      my $conf = get_config('wiggle_discrete',$lab);
      print CONF "[${d}_SUMMARY]\n";
      print CONF sprintf("%-20s","feature")."= summary\n";
      print CONF sprintf("%-20s","database")."= $d\n";
      print CONF sprintf("%-20s","name")."= sub{shift->source_tag}\n";
      print CONF sprintf("%-20s","label")."= 1\n";
      print CONF sprintf("%-20s","key")."= $d $desc\n";
      print CONF sprintf("%-20s","category")."= modENCODE Preview Tracks:$lab:summary tracks\n";
      print CONF $conf;
      print CONF sprintf("%-20s",'config set')."= wiggle_discrete\n";
      print CONF sprintf("%-20s",'citation')."= $readme_text\n\n";
    }
    if (@wig) {
      my $conf = get_config('wiggle',$lab);
      print CONF "[${d}_WIGGLE]\n";
      print CONF sprintf("%-20s","feature")."= microarray_oligo\n";
      print CONF sprintf("%-20s","database")."= $d\n";
      print CONF sprintf("%-20s","name")."= sub{shift->source_tag}\n";
      print CONF sprintf("%-20s","label")."= 1\n";
      print CONF sprintf("%-20s","category")."= modENCODE Preview Tracks:$lab:wiggle tracks\n";
      print CONF sprintf("%-20s","key")."= $d $desc\n";
      print CONF $conf;
      print CONF sprintf("%-20s",'config set')."= wiggle\n";
      print CONF sprintf("%-20s",'citation')."= $readme_text\n\n";
    }
    
    # Before initializing @classes check if unknown is the only class 
    # (if it mixed in with other classes, do not use it)
    my %realclass = map {$_=>1} grep { !/^$/ } keys %class;
    my @classes = scalar(keys %realclass) > 1 ? grep {!/basic/} keys %realclass : keys %realclass;
    map{print STDERR "  Class: $_\n"} (keys %realclass) if $debug;
    
    for my $class (@classes) {
      my $conf = get_config($class, $lab);
      print CONF "[${d}_$class]\n";
      print CONF sprintf("%-20s","feature")."= ".join(' ',@{$class{$class}})."\n";
      print CONF sprintf("%-20s","database")."= $d\n";
      print CONF sprintf("%-20s","name")."= sub{shift->source_tag}\n";
      print CONF sprintf("%-20s","label")."= 1\n";
      print CONF sprintf("%-20s","key")."= $d $desc\n";
      print CONF sprintf("%-20s","category")."= modENCODE Preview Tracks:$lab:$class\n";
      print CONF $conf;
      print CONF  sprintf("%-20s",'config set')."= $class\n";
      print CONF "citation = $readme_text\n\n";
    }
  }

  else {
    print STDERR "\n\nSubmission $d had no GFF or WIG files, what am I suppposed to do with it?\n\n";
  } 

  print STDERR "Done with submission $d!\n" if $debug;
}

print STDERR "\n-------\nDone with all processing!\n-------\n" if $debug;
  

# Figure out which species we have based on chromosome names
sub guess_species {
  my $group = shift;
  my $ref   = shift;
  my ($species,$reason);
  $species = $organism{$group};
  $reason  = "group name \"$group\"";

  unless ($species) {
    $species = 'worm' if $ref =~ /^[IV]/;
    $species = 'fly'  if $ref =~ /^[2-4U]/;
    $reason = "reference sequence name \"$ref\"";
  }

  if ($species) {
    print STDERR "    I guessed species = \"$species\" based on $reason!\n" if $species && $debug;
  }
  return $species;
}



# Stolen and modified from:
# http://www.linuxquestions.org/questions/programming-9/perl-recursion-300115/
sub recursedir {
  my $dir   = shift;
  my $list  = shift;

  if ( opendir(DIR, "$dir")) {
    #  get files, skipping hidden . and ..
    #
    print "Reading dir $dir\n";
    for my $file(grep { !/^\./ } readdir DIR) {
      if(-d "$dir/$file") {
        #  recurse subdirs
        #
        recursedir("$dir/$file", $list);
      }
      elsif(-f "$dir/$file") {
        #  add files
        #
        push @$list, "$dir/$file" unless $file =~ /\.cel$|\.pair$/i;
      }
    }
    closedir DIR;
  }
  else {
    warn "Cannot open dir '$dir': $!\n";
  }
}


# Thanks to Peter Ruzanov for contributing code
sub get_config {
  my $class = shift;
  my $lab   = shift;
  my $retval;
  
  my $conf = ConfigSet->new($class);
  print STDERR "  The default options for $class are:\n    " . (join(", ", $conf->option)) .  "\n" if $debug;
  for my $option($conf->option) {
      my @options = $conf->option($option);
      my $o = shift @options;
      if ($o) {
	  if ($option eq 'glyph' && @options) {
	      $retval .= sprintf("%-20s","glyph select")."= ".join (' ', $o, @options)."\n";
	  }
	  elsif ($option =~ /gcolor/) {
	      $o = $lab_color{$lab};
	  }
	  $retval .= sprintf("%-20s",$option)."= $o\n";
      }
  }

  my $pretty_retval = $retval;
  $pretty_retval =~ s/^/    /gm;
  print STDERR "  This is the config for $class:\n" . $pretty_retval . "\n" if $debug;
  if ($retval =~ /config set\s+=\s*quantitative/) {
      $retval =~ s/bgcolor/\#bgcolor/;
  }

  return $retval;
}


# Simple lookup table defined inside the lookup function
sub lookup {
  my $feature = shift;
  my $lab     = shift;
  my %conf_types = MyConstants::TYPES;
  my $type = $conf_types{$feature} ||  $conf_types{unknown};
  # special case for LaDeanna's genelets
  if ($type eq 'gene' && $lab eq 'Waterston') {
    $type = 'rainbow_gene';
  }
  return $type;
}

sub find_wig_and_gff {
  my ($gff,$wig,$files) = @_;
  for my $file (@$files) {
    print STDERR "I am looking at $file... " if $debug;
    my $type = 'not a data file';
    if ($file =~ /\.gff3?/) {
      push @$gff, $file;
      $type = 'a GFF file';
    }
    elsif ($file =~ /\.wig/i) {
      push @$wig, $file;
      $type = 'a WIG file';
    }
    elsif (`head $file |grep 'type=wiggle_0'`) {
#      my $newfile = $file . ".wig";
#      system "mv $file $newfile";
      push @$wig, $file;
      $type = "a WIG file, but I had to guess";
    }
    elsif (`head $file |grep '\#\#gff-version\\s*\\s3'`) {
#      my $newfile = $file . ".gff";
#      system "mv $file $newfile";
      push @$gff, $file;
      $type = "a GFF file, but I had to guess";
    }
    print STDERR "It is $type.\n" if $debug;
  }
}

sub prepare_citation {
  my $text = shift;
  my $desc = shift;
  my $lab  = shift;
  if (!$text || $lab eq 'Lai') {
    $text = $desc;
    $text = "Submission name: $text. No other information available";
  }
  else {
    my $my_text;
    open IN, $text or die $!;
    while (<IN>) {
      chomp;
      s/^\s+|\s+$//g;
      $_ or next;
      next if /^\"[^\"]+\"$/;
      $my_text .= $_ . "\n  " if $_;
    }
    $text = $my_text;
  }

  $text =~ s/\n/\n /gm;
  return $text;
}

sub are_we_sure_this_is_good_gff {
  local $_ = shift;
  chomp;
  my @cells = split "\t";
  return 0 unless @cells >= 8 && @cells < 10;
  my ($start,$end,$score,$strand,$phase,$att) = @cells[3..8];
  return 0 unless $start =~ /^\d+$/ && $end =~ /^\d+$/;
  return 1;
}

