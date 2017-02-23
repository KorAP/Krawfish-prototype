package Krawfish::Result::Aggregate::Length;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

# This will check the segments length -
# currently other word lengths are not supported

# See https://en.wikipedia.org/wiki/Selection_algorithm
# for algorithms to find the median or similar.

sub new {
  my $class = shift;
  bless {
    min => 32_000,
    max => 0,
    sum => 0,
    freq => 0
  }, $class;
};


sub each_doc {};


sub each_match {
  my ($self, $current) = @_;
  my $length = $current->end - $current->start;
  $self->{min} = $length < $self->{min} ? $length : $self->{min};
  $self->{max} = $length > $self->{max} ? $length : $self->{max};
  $self->{sum} += $length;
  $self->{freq}++;
};


sub result {
  my $self = shift;
  return if $self->{freq} == 0;
  return {
    length => {
      min  => $self->{min},
      max  => $self->{max},
      sum  => $self->{sum},
      avg  => $self->{sum} / $self->{freq}
    }
  };
};

sub to_string {
  'length'
};

1;
