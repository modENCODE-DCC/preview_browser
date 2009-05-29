package ConfigSet::wiggle;
use strict;
use base 'ConfigSet';

use constant OPTIONS => ( 
  glyph              => [qw/wiggle_xyplot wiggle_density/],
  fgcolor            => [qw/black red/],
  bgcolor            => [qw/black blue red green white/],
  smoothing          => [qw/mean max min median none/],
  'smoothing window' => [1..16],
  min_score          => undef,
  max_score          => undef,
  neg_color          => [qw/orange red/],
  pos_color          => [qw/blue green/],
  graph_type         => [qw/boxes histogram/],
  height             => [30,10,15,20,25,25,40,45,50],
  autoscale          => [qw/local global/],
  variance_band      => [0,1],
  scale_color        => [qw/red black blue/],
  clip               => [0,1],  
  #etc...
    );

sub new {
  my $class = shift;
  my $self = bless {}, ref $class || $class;
  $self->initialize();
  return $self;
}

# set initial options -- can be reset later
sub initialize {
  my $self = shift;
  my %options = OPTIONS;
  for my $option (keys %options) {
    $self->{option}->{$option} = $options{$option};
  }
}


1;


