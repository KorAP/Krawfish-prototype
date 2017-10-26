package Krawfish::Compile::Segment::Aggregate::Length;
use parent 'Krawfish::Compile::Segment::Aggregate::Base';
use Krawfish::Log;
use strict;
use warnings;

# This will check the hits length in subtokens -
# currently other word lengths are not supported

# See https://en.wikipedia.org/wiki/Selection_algorithm
# for algorithms to find the median or similar.


use constant DEBUG => 0;

sub new {
  my ($class, $flags) = @_;

  return bless {
    flags => $flags,
    result => Krawfish::Koral::Result::Aggregate::Length->new($flags)
  }, $class;

  # DELETE:
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
  $self->{result}->incr_match(
    $current->end - $current->start,
    $current->flags($self->{flags})
  );
};

sub result {
  $_[0]->{result};
};


# Stringification
sub to_string {
  'length'
};


1;
