package Krawfish::Query::Cache;
use parent 'Krawfish::Query';
use Krawfish::Index::Stream;
use Krawfish::Cache;
use strict;
use warnings;

# Cache implementation for queries

sub new {
  my $class = shift;
  my $self = bless {
    span => shift,
    cache => (shift // Krawfish::Cache->new),
    doc_id => undef,
    flags  => undef
  }, $class;
  return $self;
};


# Move to next posting
# The doc_ids are not stored as deltas,
# so sorting with offstes is supported
sub next {
  ...
};


# Get maximum frequency
sub max_freq {
  ...
};


# Clone query
sub clone {
  ...
};


# Requires filtering
sub requires_filter {
  ...
};

1;
