package ConfigSet::point;

use strict;
use base 'ConfigSet';

use constant OPTIONS => ( 
  bgcolor    => [qw/blue white gray black red yellow green orange magenta cyan peachpuff /],
  fgcolor    => [qw/blue white gray black red yellow green orange magenta cyan peachpuff /],			  
  glyph      => [qw/triangle diamond/],
  orient     => [qw/N S E W/], # applies to triangle
  height     => [5..20],
  point      => 1,			  
  bump       => [0..3],
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
