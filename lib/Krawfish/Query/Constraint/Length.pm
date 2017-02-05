package Krawfish::Query::Constraint::Length;
use strict;
use warnings;

# TODO: THIS IS CURRENTLY JUST A MOCKUP

# TODO: This should respect different tokenizations!

sub new {
  my $class = shift;
  bless {
    min => shift,
    max => shift,
    tokens => shift
  }, $class;
};

sub min {
  $_[0]->[0];
};

sub max {
  $_[0]->[1];
};


# Overwrite
sub check {
  my ($self, $span) = @_;

  # Check if the length is between the given boundaries
  if (
    ($span->start + $self->min <= $span->end) &&
      ($span->start + $self->max >= $span->end)
  ) {
    return 1;
  }
  return 0;
};


1;
