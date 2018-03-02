package Krawfish::Koral::Compile::Group::Aggregate;
use Krawfish::Koral::Compile::Node::Group::Aggregate;
use Krawfish::Log;
use List::MoreUtils qw/uniq/;
use strict;
use warnings;

use constant DEBUG => 0;

# TODO:
#   Check that only valid aggregate objects are passed

# TODO:
#   If a change is made here, check for
#   Krawfish::Koral::Compile::Aggregate
#   as well.

# Prepare Group Aggregations

# Constructor
sub new {
  my $class = shift;
  bless [@_], $class;
};


# Aggregation type
sub type {
  'group_aggregate';
};


# Get or set operations
# TODO:
#   Identical to Compile::Aggregate
sub operations {
  my $self = shift;
  if (@_) {
    @$self = @_;
    return $self;
  };
  return @$self;
};


# Wrap aggregates in each other
sub wrap {
  my ($self, $query) = @_;

  if (DEBUG) {
    print_log('kq_gaggr', 'Wrap operation ' . join(',', @$self));
  };


  # Join aggregates
  return Krawfish::Koral::Compile::Node::Group::Aggregate->new(
    $query,
    [$self->operations]
  );
};


# Normalize aggregations
# This is similar to Compile::Aggregate, but does not sort
# aggregations to keep columns intact
sub normalize {
  my $self = shift;

  my @ops = @$self;

  # Check for doubles
  for (my $i = 1; $i < @ops; $i++) {

    # Two consecutive operations are identical
    if ($ops[$i]->type eq $ops[$i-1]->type) {

      # Merge fields or values
      if ($ops[$i]->type eq 'fields' || $ops[$i]->type eq 'values') {
        $ops[$i-1]->operations(
          $ops[$i-1]->operations,
          $ops[$i]->operations
        );

        # Remove double operation
        splice(@ops, $i, 1);
        $i--;
      }

      else {
        # Remove double operation
        splice(@ops, $i, 1);
      };

      CORE::next;
    };

    # Normalize when no longer consecutive operations
    # can be expected
    $ops[$i-1] = $ops[$i-1]->normalize;
  };

  # Normalize last operation
  $ops[-1] = $ops[-1]->normalize;

  $self->operations(@ops);

  return $self;
};


# Stringification
sub to_string {
  my ($self, $id) = @_;
  return 'gaggr=[' . join(',', map { $_->to_string($id) } @$self) . ']';
};


1;
