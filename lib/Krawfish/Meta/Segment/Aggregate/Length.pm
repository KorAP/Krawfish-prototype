package Krawfish::Meta::Segment::Aggregate::Length;
use parent 'Krawfish::Meta::Segment::Aggregate::Base';
use Krawfish::Log;
use strict;
use warnings;

# This will check the segments length -
# currently other word lengths are not supported

# See https://en.wikipedia.org/wiki/Selection_algorithm
# for algorithms to find the median or similar.


use constant DEBUG => 0;

sub new {
  my $class = shift;
  bless {
    segment => shift,
    query => shift,
    min  => 32_000,
    max  => 0,
    sum  => 0,
    freq => 0
  }, $class;
};


# On every match
sub each_match {
  my ($self, $current) = @_;
  my $length = $current->end - $current->start;
  $self->{min} = $length < $self->{min} ? $length : $self->{min};
  $self->{max} = $length > $self->{max} ? $length : $self->{max};
  $self->{sum} += $length;
  $self->{freq}++;
};


# Finish the aggregation
sub on_finish {
  my ($self, $collection) = @_;

  return if $self->{freq} == 0;
  $collection->{length} = {
    min  => $self->{min},
    max  => $self->{max},
    sum  => $self->{sum},
    avg  => $self->{sum} / $self->{freq}
  };
};


# Stringification
sub to_string {
  'length'
};

1;
