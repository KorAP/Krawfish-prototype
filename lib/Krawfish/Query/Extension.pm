package Krawfish::Query::Extension;
use strict;
use warnings;
use Role::Tiny::With;

with 'Krawfish::Query::Base::Dual';
with 'Krawfish::Query';

# This query adds subtokens to the left or the right
# of a matching span
#
# Support gaps like with Constraint::InBetween


# Constructor
sub new {
  my $class = shift;
  bless {
    left => shift,
    min => shift,
    max => shift,
    span => shift,
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
  $string .= $self->{left} ? 'left' : 'right';
  $string .= $self->{min} . ',' $self->{max};
  return $string . $self->{span}->to_string . ')';
};


# Get maximum frequency
sub max_freq {
  $_[0]->{span}->max_freq;
};


# Filter query by VC
sub filter_by {
  ...
};


# Requires filtering
sub requires_filter {
  return $_[0]->{span}->requires_filter;
};


1;
