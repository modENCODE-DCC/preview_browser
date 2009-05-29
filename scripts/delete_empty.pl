#!/usr/bin/perl

opendir(DIR,'.') or die "Couldn't read from current directory";

my @dirs = grep { /^\d/ } readdir(DIR);
print STDERR "Got ".scalar(@dirs)." directories\n";
close DIR;

foreach my $d (@dirs) {
 next if ! -d $d; # skip non-dirs
 opendir(DIR,$d) or die "Couldn't read from $d";
 my $del_ok = scalar(grep { !/^\.\.?$/ } readdir(DIR)) == 0 ? 1 : 0;
 print STDERR "Directory $d marked for ".($del_ok == 1 ? "deletion\n" : "keeping\n");
 close DIR;

 if ($del_ok) {
  print STDERR "Dir $d is empty, deleting...\n";
  `rmdir $d`;
 }
}

