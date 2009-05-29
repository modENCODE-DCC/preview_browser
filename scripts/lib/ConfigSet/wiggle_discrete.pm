package ConfigSet::wiggle_discrete;

use strict;
use base 'ConfigSet';

use constant OPTIONS => ( 
  fgcolor         => [qw/black red/],
  bgcolor         => [qw/blue black red green white/],
  glyph           => [qw/wiggle_box/],
  height          => [5..8],
  scale           => [0..1],
  label_position  => [qw/top left/],
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
