package Krawfish::Compile::Segment::Aggregate::Frequencies;
use Krawfish::Koral::Result::Aggregate::Frequencies;
use Krawfish::Log;
use strict;
use warnings;
use Role::Tiny;

with 'Krawfish::Compile::Segment::Aggregate::Base';

use constant DEBUG => 0;

# Count the frequencies of all matches of the query
# per doc and per match.

# This is not a query but an aggregation object!
# Aggregations are collected using the aggregate()
# method at the end.

# TODO:
#   Add flags list to stringification

# TODO:
#   Support flags on construction


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

  if (DEBUG) {
    print_log('a_freq', 'Remember doc ' . $current->doc_id . ' on frequency');
  };

  # Increment on flag value
  $self->{result}->incr_doc($flags);
};


# Add to totalResults immediately
sub each_match {
  my ($self, $current) = @_;

  # Mix set flags with flags to aggregate on
  my $flags = $current->flags($self->{flags});

  if (DEBUG) {
    print_log('a_freq', 'Remember match in doc ' . $current->doc_id . ' on frequency');
  };

  # Increment on flag value
  $self->{result}->incr_match($flags);
};


# Stringification
sub to_string {
  'freq'
};

1;

