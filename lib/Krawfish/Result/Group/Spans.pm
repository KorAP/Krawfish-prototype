package Krawfish::Result::Group::Spans;
use parent 'Krawfish::Result';
use Krawfish::Log;
use strict;
use warnings;

# This may be genralizable, but for the moment
# It should make it possible to group the span positions
# of a query based on a nesting query.
#
# The idea is to make the following possible:
# Search for a term in sentences (like "{1:contains(<s>, {2:'baum'})}") and
# based on the position and length of 1 and 2,
# a result like
#
#     0: 5
#     1: 7
#   100: 2
#
# can be returned, where each class 1 is sliced in
# 100 pieces and for each pieces there is a dot, in case
# class 2 occurs in that slice.
#
# By doing that it's easy to visualize the position of expressions
# in sentences or documents etc.
#
# For example to answer questions like (where in documents does
# the phrase "Herzlichen Dank" occur.
#
# If the span spans more than 1 slice, the result can be
#
#   0_2: 1
#   0_3: 4
#   4: 6
#
# etc. In case the second class is not nested in the first
# class, this is not counted at all (as this would result
# in weird data regarding the slice sizes).

sub new {
  my $class = shift;
  my %param = @_;
  bless {
    slices => $param{slices} // 100,
    wrap_clas => $param{wrap_class} // 1,
    embedded_class => $param{embedded_class} // 2
  }, $class;
};

# Get the group signature for each match
# May well be renamed to get_signature
sub get_group {
  my $self = shift;
  my $slice_start = 0;
  my $slice_end = 0;
  return $slice_start . '_' . $slice_end;
};

1;
