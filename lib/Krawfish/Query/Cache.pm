package Krawfish::Query::Cache;
use parent 'Krawfish::Query';
use Krawfish::Index::Stream;
use Krawfish::Cache;
use strict;
use warnings;

sub new {
  my $class = shift;
  my $self = bless {
    span => shift,
    cache => (shift // Krawfish::Cache->new),
    doc_id => undef
  }, $class;
  return $self;
};

# The doc_ids are not stored as deltas,
# so sorting with offstes is supported
sub next {
  ...
};

sub max_freq {
  ...
};

sub clone {
  ...
};

1;
