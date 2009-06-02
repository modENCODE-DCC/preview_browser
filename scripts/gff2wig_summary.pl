#!/usr/bin/perl
# Script to turn GFF features into a wiggle binary file
# The point is to make a high-level summary view with little detail
# Thanks to EO Stinson for the original script template
use strict;
my $root_dir;
BEGIN {
  $root_dir = $0;
  $root_dir =~ s/[^\/]*$//;
  $root_dir = "./" unless $root_dir =~ /\//;
  push @INC, $root_dir . "/lib";
}
use Bio::Graphics::Wiggle;
use Digest::MD5 'md5_hex';
use MyConstants;
use Data::Dumper;

use constant TMP    => '/tmp';
use constant UNLINK => 1;
use constant OUT    => 'wib'; 
use constant TYPE   => 'summary';

my $debug = MyConstants::DEBUG;
my %refseq_OK    = map {$_ => 1}  MyConstants::REFSEQ;

use vars qw/%TYPE %GFF/;

# First, we need to do some sorting.
# We rely on I/O here because we have no idea how big that file is going to be
my $usage = <<END
  Usage: gff2wig.pl gff_file outpath file_type
         outpath   = path for wib files (default ./wib)
         file_type = 'peak' or 'summary' (default 'summary')
END
;

my $infile    = shift || die $usage;
my $outpath   = shift || OUT;
my $file_type = shift || TYPE;

(my $gffout  = $infile )=~ s/(\.gff3?)/_$file_type$1/;
my $tmp     = TMP . "/" . md5_hex($$*rand());

mkdir $tmp unless -d $tmp;

chomp(my $pwd = `pwd`);
if ($outpath =~ /^\./) {
  $outpath =~ s/^\./$pwd/;
}
if ($outpath !~ /^\//) {
  $outpath = "$pwd/$outpath";
}


my (%min,%max,$line);
open IN, ($infile =~ /\.gz$/ ? "zcat $infile |" : $infile) 
    or die "Could not open $infile!: $!\n";
while (<IN>) {
  !/^\#/ or next;
  my @fields = split "\t";
  @fields >= 7 or next;
  my ($ref,$src,$met,$start,$end) = @fields[0..4];

  # Filter unwanted refseqs
  next unless $refseq_OK{$ref};

  # Let's just worry about top-level features
  next if /Parent=/;

  # Skip features lacking coordinates -- what is the point of these?
  # Seriously folks, it is a genome browser!
  next unless $start && $end;


  my $temp = temp_file($ref,$src,$met);
  print $temp $_;

  $min{$ref} ||= {};
  $max{$ref} ||= {}; 

  my $type = "$met:$src";
  $min{$ref}{$type} = $start if !$min{$ref}{$type} || $min{$ref}{$type} > $start;
  $max{$ref}{$type} = $start if !$max{$ref}{$type} || $max{$ref}{$type} < $end;
}

# close all file handles
close_all();

# Now, make wiggle tracks of all the GFF sub-files
print STDERR "      Now preparing wiggle files\n" if $debug;
open GFFOUT, "|gzip -c >'$gffout'" or die "Could not open outfile";
print GFFOUT "##gff-version 3\n";

#print STDERR Dumper(\%GFF) if $debug;

for my $chr (keys %GFF) {
  my $types = $GFF{$chr};
  while (my ($type,$label) = each %$types) {
    my ($met,$src) = $type =~ /([^\|]+)\:(\S+)/;
    make_wigfile($chr,$src,$met,$label);
  }
}
print STDERR "      Done: The GFF is in $gffout\n" if $debug;

clean_up();


# create a read/write temp file for each ref seq and feature type
sub temp_file {
  my $hextype = md5_hex(@_);
  my $type = join(':',@_[2,1]);
  $GFF{$_[0]}{$type} = $hextype;
  open my $fh, ">>$tmp/$hextype.gff" or die $!;
  return $fh;
}

sub close_all {
  for my $name (keys %TYPE) {
    close $TYPE{$name};
  }
}

sub clean_up {
  system "rm -fr $tmp";
}

sub make_wigfile {
  my ($chr,$src,$met,$wig_name) = @_;

  print STDERR "        Writing wib file for $chr $met:$src\n" if $debug;

  mkdir($outpath) unless -d $outpath;
  my $wig_db_file = "$outpath/$wig_name.wib";  

  my $min = $min{$chr}{"$met:$src"};
  my $max = $max{$chr}{"$met:$src"};
  
  my $wigfile = new Bio::Graphics::Wiggle(
					  $wig_db_file,
					  1, # writeable
					  {
					    seqid => $chr,
					    min => int($min),
					    max => int($max),
					    step => 1,
					    span => 1,
					  }
					  );
  my ($startmin, $endmax);
  my $accum = 0;
  
  open GFF, "grep '\^$chr\[\^0-9A-Za-z\]' $tmp/$wig_name.gff |" or die "GFF file not found";

  my $ln = 0;
  while (<GFF>) {
    my ($ref,$start,$end) = (split)[0,3,4];
    $ref eq $chr or next; # belt and suspenders
    $wigfile->set_range($start => $end, 255);
  }
  
  $wigfile->mean(255);
  $wigfile->stdev(0);
  
  print GFFOUT join("\t",$chr,"${src}_$met",'summary',$min,$max,qw/. . ./,"Name=${chr}:${met}:${src};wigfile=$wig_db_file\n"); 

}
