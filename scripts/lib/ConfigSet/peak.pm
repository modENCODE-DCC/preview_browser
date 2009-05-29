package ConfigSet::peak; 
use strict;
use base 'ConfigSet';

use constant OPTIONS => ( 
  fgcolor         => [qw/black red/],
  bgcolor         => [qw/limegreen blue green white/],
  glyph           => ['generic'],
  height          => [5..8],
  linewidth       => [1..3],
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
