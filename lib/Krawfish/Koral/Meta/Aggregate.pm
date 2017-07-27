package Krawfish::Koral::Meta::Aggregate;
use List::MoreUtils qw/uniq/;
use strict;
use warnings;

# TODO:
#   Check that only valid aggregate objects are passed

our %AGGR_ORDER = (
  'length' => 1,
  'freq'   => 2,
  'facets' => 3
);

sub new {
  my $class = shift;
  bless [@_], $class;
};


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

sub to_nodes {
  my ($self, $query) = @_;
  warn 'TODO';
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

      # Merge facets
      if ($ops[$i]->type eq 'facets') {
        $ops[$i-1]->operations(
          $ops[$i-1]->operations,
          $ops[$i]->operations
        )
      };

      # Remove double operation
      splice(@ops, $i, 1);

      next;
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


sub to_string {
  my $self = shift;
  return 'aggr=[' . join(',', map { $_->to_string } @$self) . ']';
};

1;
