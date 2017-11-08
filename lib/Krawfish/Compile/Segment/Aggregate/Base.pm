package Krawfish::Compile::Segment::Aggregate::Base;
use strict;
use warnings;
use Role::Tiny;

requires qw/each_doc
            each_match
            on_finish
            result
            to_string/;

# Per default do nothing
sub on_finish {
  $_[0];
};

# Get result object
sub result {
  my $self = shift;
  if ($_[0]) {
    $self->{result} = shift;
    return $self;
  };
  # $self->{result} //= Krawfish::Koral::Result->new;
  return $self->{result};
};

1;
