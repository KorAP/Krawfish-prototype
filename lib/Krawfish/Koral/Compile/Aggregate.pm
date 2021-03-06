package Krawfish::Koral::Compile::Aggregate;
use Krawfish::Koral::Compile::Node::Aggregate;
use Krawfish::Log;
use List::MoreUtils qw/uniq/;
use strict;
use warnings;

use constant DEBUG => 0;

# TODO:
#   Check that only valid aggregate objects are passed

# TODO:
#   If a change is made here, check for
#   Krawfish::Koral::Compile::Group::Aggregate
#   as well.

our %AGGR_ORDER = (
  'length' => 1,
  'freq'   => 2,
  'fields' => 3,
  'values' => 4
);


# Constructor
sub new {
  my $class = shift;
  bless [@_], $class;
};


# Aggregation type
sub type {
  'aggregate';
};


# Get or set operations
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
    print_log('kq_aggr', 'Wrap operation ' . join(',', @$self));
  };

  # Join aggregates
  return Krawfish::Koral::Compile::Node::Aggregate->new(
    $query,
    [$self->operations]
  );

  return $query;
};


# Normalize aggregations
sub normalize {
  my $self = shift;

  # Sort objects in defined order
  my @ops = sort {
    $AGGR_ORDER{$a->type} <=> $AGGR_ORDER{$b->type}
  } @$self;

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
  return 'aggr=[' . join(',', map { $_->to_string($id) } @$self) . ']';
};


1;
