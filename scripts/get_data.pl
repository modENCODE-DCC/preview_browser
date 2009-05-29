#!/usr/bin/perl -w
use strict;

use constant URL => 'http://submit.modencode.org/submit/public/download_tarball';

# targetted download of listed submissions only
open KEY, "../submission_data/submission_key.txt";

chdir "../uploads" or die $!;

while (<KEY>) {
  chomp;
  my ($sid) = split "\t";
  $sid or next;
  next if -d $sid || -e "$sid.tar.gz";

  #"system rm -fr $sid";

  # download tarball from LBNL
  my $url = URL . "/$sid?root=data&structured=true";
  system "wget '$url' -O $sid.tar.gz";

  # upack and get rid of the tarball
  next unless -e "$sid.tar.gz" && ! -z "$sid.tar.gz";
  `mkdir -m 775 $sid`;
  system "tar -C $sid -xzvf $sid.tar.gz";
  #unlink "$sid.tar.gz";

}
