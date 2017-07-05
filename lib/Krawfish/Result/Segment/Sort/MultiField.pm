package Krawfish::Result::Segment::Sort::MultiField;
use strict;
use warnings;

# Sorting criterion for multi value field ranks.

# See Krawfish::Result::Segment::Sort::Field

sub new {
  my $class = shift;

  my $self = bless {
    index => shift,
    field => shift,
    descending => shift // 0
  }, $class;

  # Get ranking
  # TODO: Depending on the descending value, different rankings need to be loaded

  return $self;
};


sub get {
  my $self = shift;

  # Get stored rank
  return $self->{ranking}->get(shift);
};
