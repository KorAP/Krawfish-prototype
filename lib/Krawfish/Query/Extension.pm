package Krawfish::Query::Extension;
use strict;
use warnings;
use Role::Tiny::With;

with 'Krawfish::Query';

use constant DEBUG => 0;

# This query adds subtokens to the left or the right
# of a matching span
#
# TODO:
#   Support gaps like with Constraint::InBetween


# Constructor
sub new {
  my $class = shift;
  bless {
    left => shift,
    min => shift,
    max => shift,
    span => shift,
    buffer => Krawfish::Util::Buffer->new
  }, $class;
  # min, max ...
};


# Clone query
sub clone {
  ...
};


# Check the configuration
sub check {
  ...
};


# Stringification
sub to_string {
  my $self = shift;
  my $string ='ext(';
  $string .= $self->{left} ? '<' : '>';
  $string .= ':' . $self->{min} . '-' . $self->{max};
  return $string . ',' . $self->{span}->to_string . ')';
};


# Get maximum frequency
sub max_freq {
  return $_[0]->{span}->max_freq * (($_[0]->{max} - $_[0]->{min}) + 1);
};


# Filter query by VC
sub filter_by {
  ...
};


# Requires filtering
sub requires_filter {
  return $_[0]->{span}->requires_filter;
};


# Move to next posting
sub next {
  # right extensions just add
  # right tokens and match,
  # as long as the document span is not reached

  # left extensions require a buffer
  # with the size of max (+1?) to hold
  # candidates
  ...
};

1;
