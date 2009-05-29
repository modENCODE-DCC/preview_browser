package ConfigSet::hybrid_wiggle;

use strict;
use base 'ConfigSet';

use constant OPTIONS => ( 
  fgcolor         => [qw/black red/],
  bgcolor         => [qw/black blue red green white/],
  glyph          => [qw/hybrid_plot/],
  height          => [20..40],
  scale           => [0..1],
  neg_color       => [qw/orange green/],
  pos_color       => [qw/blue red/],
  label_position  => [qw/left/],
  max_score       => undef,
  min_score       => undef,
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
