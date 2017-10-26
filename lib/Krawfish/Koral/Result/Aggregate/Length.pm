package Krawfish::Koral::Result::Aggregate::Length;
use strict;
use warnings;

# This calculates frequencies for all classes

# TODO:
#   Instead of keys a byte-trie may in the end
#   be the most efficient data structure.

# Constructor
sub new {
  my $class = shift;
  bless {
    flags => shift,
    freq => 0,
    min => 32_000_000,
    max => 0,
    sum => 0
  }, $class;
};


# Increment value per document
sub incr_match {
  my ($self, $length, $flags) = @_;
  $self->{min} = $length < $self->{min} ? $length : $self->{min};
  $self->{max} = $length > $self->{max} ? $length : $self->{max};
  $self->{sum} += $length;
  $self->{freq}++;
};


# Inflate result
sub inflate {
  $_[0];
};


# Finish the calculation
sub on_finish {
  my $self = shift;
  return $self if $self->{freq} == 0;
  $self->{avg} = $self->{sum} / $self->{freq};
  return $self;
};


# Stringification
sub to_string {
  my $self = shift;
  my $str = '[length=';
  $str .= '[';
  $str .= 'avg:' . $self->{avg} . ';';
  $str .= 'min:' . $self->{min} . ';';
  $str .= 'max:' . $self->{max} . ';';
  $str .= 'sum:' . $self->{sum};
  return $str . ']';
};


sub key {
  'length';
};

1;
