package Krawfish::Koral::Result::Group::Aggregate;
use strict;
use warnings;

# Return an object to collect aggregations
# for a group

# TODO:
#   All aggregations on groups should add their data here

# TODO:
#   Join with Krawfish::Koral::Util::Row

# TODO:
#   Join with Krawfish::Koral::Result::Aggregate

# The structure should be:

# {
#   $criterion => {
#     $flag => {
#       $aggregate => []
#     }
#   }
# }

# TODO:
#   Flags should probably be in a sorted list
#   with objects per Group::Aggregate

# TODO:
#   Each aggregation method may have an index,
#   so the can directly access their data in the array.

sub new {
  my $class = shift;
  bless {}, $class;
};


sub flags {
  my ($self, $flags) = @_;

  return $self->{$flags} //= [];
};


1;
