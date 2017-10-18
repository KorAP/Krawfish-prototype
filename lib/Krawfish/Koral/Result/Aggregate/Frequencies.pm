package Krawfish::Koral::Result::Aggregate::Frequencies;
use strict;
use warnings;

# This calculates frequencies for all classes

# TODO:
#   Alternatively increment on all 16^2=65536 combinations
#   And separate + sum them afterwards
#   (so the array would be 2*(16^2)*size(long))

sub new {
  my $class = shift;
  bless {
    classes => [@_],
    freqs => []
  }, $class;
};

# Increment value per document
sub incr_doc {
  my ($self, $class) = @_;
  $self->{freqs}->[$class * 2]++;
};

# Increment value per document
sub incr_match {
  my ($self, $class) = @_;
  $self->{freqs}->[$class * 2 + 1]++;
};

sub inflate {
  $_[0];
};

sub to_string {
  my $self = shift;
  my $str = 'freq=';
  foreach (@{$self->{classes}}) {
    $str .= $_ == 0 ? 'total' : $_;
    $str .= ':[' . $self->{freqs}->[$_ * 2] . ',' .  $self->{freqs}->[$_ * 2 + 1] . ']';
    $str .= ';';
  };
  chop($str);
  return $str;
};


sub key {
  'frequencies';
};

1;
