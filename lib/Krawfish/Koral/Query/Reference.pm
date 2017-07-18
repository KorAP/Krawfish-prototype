package Krawfish::Koral::Query::Reference;

# May be renamed to "Pointer"
# Reference queries consist of two types,
# the source and the reference.
# The source ref() will always be around the whole
# query, so the subquery is lifted at the beginning.
# The references (#n) will then point to the
# cached subquery.
#
#   ref(1:[a&b],(#1)[]{2,3}(#1))


use Krawfish::Log;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless {

    # The signature of the reference query
    signature => shift,
    query => shift
  }, $class;
};

sub to_koral_fragment;

sub type { 'reference' };

sub remove_classes;

# Not necessary here
sub filter_by;

sub to_string {
  'ref(#' . $_[0]->{signature} . ')';
};

sub is_extended_left;
sub is_extended_right;
sub is_extended;
sub maybe_unsorted;
1;
