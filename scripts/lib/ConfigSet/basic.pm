package ConfigSet::basic;

use strict;
use base 'ConfigSet';


use constant OPTIONS => ( 
  bgcolor    => [qw/cyan gray black red yellow green orange magenta/ ],
  fgcolor    => [qw/black cyan gray red yellow green orange magenta/ ],
  glyph      => [qw/generic box segments span/],
  height     => [5..12],
  bump       => [1,0,2,33],
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
