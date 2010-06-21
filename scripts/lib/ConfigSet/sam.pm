package ConfigSet::sam;
use strict;
use base 'ConfigSet';

use constant OPTIONS => ( 
  glyph              => [qw/segments/],
  fgcolor            => [qw/blue black red/],
  bgcolor            => [qw/blue black red green white/],
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


