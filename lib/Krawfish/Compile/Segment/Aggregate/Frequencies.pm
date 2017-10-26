package Krawfish::Compile::Segment::Aggregate::Frequencies;
use parent 'Krawfish::Compile::Segment::Aggregate::Base';
use Krawfish::Koral::Result::Aggregate::Frequencies;
use Krawfish::Log;
use strict;
use warnings;

# Count the frequencies of all matches of the query
# per doc and per match.

# This is not a query but an aggregation object!
# Aggregations are collected using the aggregate()
# method at the end.

# TODO:
#   Add flags list to stringification


# Constructor
sub new {
  my ($class, $flags) = @_;
  bless {
    flags => $flags,
    result => Krawfish::Koral::Result::Aggregate::Frequencies->new($flags)
  }, $class;
};


# Add to totalResources immediately
sub each_doc {
  my ($self, $current) = @_;

  # Mix set flags with flags to aggregate on
  my $flags = $current->flags($self->{flags});

  # Increment on flag value
  $self->{result}->incr_doc($flags);
};


# Add to totalResults immediately
sub each_match {
  my ($self, $current) = @_;

  # Mix set flags with flags to aggregate on
  my $flags = $current->flags($self->{flags});

  # Increment on flag value
  $self->{result}->incr_match($flags);
};


# Return result blob
sub result {
  $_[0]->{result};
};


# Stringification
sub to_string {
  'freq'
};

1;

