package Krawfish::Koral::Result::Enrich::Criteria;
use strict;
use warnings;
use Role::Tiny::With;
use Scalar::Util qw/looks_like_number/;
use Krawfish::Util::String qw/binary_short/;

with 'Krawfish::Koral::Result::Inflatable';

# Enrich with sorting criteria, necessary
# for sorting on node and cluster level.


# Constructor
sub new {
  my $class = shift;
  bless [], $class;
};


# Key for enrichment
sub key {
  'sortedBy';
};


# Set a single sort criterion
sub criterion {
  my ($self, $level, $criterion) = @_;
  $self->[$level] = $criterion;
};


# Stringification
sub to_string {
  my ($self, $id) = @_;
  my $str = '';
  $str .= join(',', map { binary_short($_) } @$self);
  return $str;
};


# Serialize to KoralQuery
sub to_koral_fragment {
  # sortedBy : [
  #   {
  #     "@type" : "koral:field" # either numeric or binary
  #     ...
  #   },
  #   {
  #     "@type" : "koral:string"
  #     ...
  #   }
  # ]
  ...
};


# Inflate (nothing to do)
sub inflate {
  $_[0]
};


1;
