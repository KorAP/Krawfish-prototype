package Krawfish::Koral::Result::Enrich::SortCriterion;
# TODO:
#   Rerename to Criteria
use strict;
use warnings;
use Role::Tiny::With;
use Scalar::Util qw/looks_like_number/;
use Krawfish::Util::String qw/binary_short/;

with 'Krawfish::Koral::Result::Inflatable';

# Smilar to Snippet, this will add the surface information
# for all sorting criteria to make sorting possible for
# cluster sorting.

# sortedBy : [
#   {
#     "@type" : "koral:field"
#     ...
#   },
#   {
#     "@type" : "koral:string"
#     ...
#   }
# ]


sub new {
  my $class = shift;
  bless [], $class;
};


# Set criterion
sub criterion {
  my ($self, $level, $criterion) = @_;
  $self->[$level] = $criterion;
};


sub to_koral_fragment {
  ...
};


# Stringification
sub to_string {
  my ($self, $id) = @_;
  my $str = '';
  $str .= join(',', map {
    binary_short($_)
  } @$self);
  return $str;
};


# Inflate term ids to terms
sub inflate {
  ...
};

1;
