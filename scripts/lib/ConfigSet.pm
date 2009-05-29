package ConfigSet;

=head1 NAME

Bio::Graphics::Browser::ConfigSet -- a base class for track config sets

=head1 SYNOPSIS

 use Bio::Graphics::Browser::ConfigSet;
 my $basic  = Bio::Graphics::Browser::ConfigSet->new('basic');
 my @glyphs = $basic->options('glyph');
 push @glyphs, 'weird_glyph';
 $basic->options('glyph',@glyphs);

=cut


use strict;
use File::Spec;
use Carp 'croak';
use Symbol;

sub new {
  my $class = shift;
  my $set   = shift || 'basic';
  return _load_module(lc $set);
}

sub _load_module {
  my $set = shift;
  #my $setmod = "Bio::Graphics::Browser::ConfigSet::$set";
  my $setmod = "ConfigSet::$set";
  require File::Spec->catfile(split '::', $setmod.'.pm');
  return  $setmod->new();
}


# a generic getter/setter for lists of possible values
# for config options. The set-specific values are defined in 
# the initialize method of each ConfigSet subclass
sub option {
  my ($self,$option,@values) = @_;
  $option or return keys %{$self->{option}};
  $self->{option}->{$option} = \@values if @values;
  $self->{option}->{$option} ||= [];
  $self->_process_colors();
  return @{$self->{option}{$option}};
}

sub _process_colors {
  my $self = shift;
  my @coloropts = grep /color/, keys %{$self->{option}};
  for my $c (@coloropts) {
    my @colors = @{$self->{$c}} if $self->{$c};
    @colors > 0 or next;
    for (0..$#colors) {
      $self->{option}->{$c}->[$_] =~ s/^([0-9A-Fa-f]{6})$/\#$1/;
    }
  }
  $self->{option}->{bgcolor} ||= $self->{option}->{fgcolor} if $self->{option}->{fgcolor};
  $self->{option}->{fgcolor} ||= $self->{option}->{bgcolor} if $self->{option}->{bgcolor};
}

1;
