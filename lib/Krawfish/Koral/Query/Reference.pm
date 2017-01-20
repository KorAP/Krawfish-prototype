package Krawfish::Koral::Query::Reference;

# May be renamed to "Pointer"

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

sub plan_for;



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
