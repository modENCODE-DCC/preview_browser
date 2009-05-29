package ConfigSet::rainbow_gene;

use strict;
use base 'ConfigSet';

use constant OPTIONS => (
  glyph             => [qw/rainbow_gene/],
  height            => [5..10],
  linewidth         => [1..3],
  label_transcripts => [0..1],
  transcript_only   => [0..1],
  connector         => [0..2],
  connector_color   => [qw/black blue green red/],
  start_color       => [qw/blue red green yellow magenta/];
  end_color         => [qw/red blue green yellow magenta/];		 
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
