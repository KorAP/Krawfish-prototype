package Krawfish::Compile::Segment::Aggregate::Length;
use Krawfish::Log;
use strict;
use warnings;
use Role::Tiny::With;

with 'Krawfish::Compile::Segment::Aggregate::Base';

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
};


# Clone operation
sub clone {
  return __PACKAGE__->new($_[0]->{flags});
};


# On every match
sub each_match {
  my ($self, $current) = @_;
  $self->{result}->incr_match(
    $current->end - $current->start,
    $current->flags($self->{flags})
  );
};


# Stringification
sub to_string {
  'length'
};


1;
