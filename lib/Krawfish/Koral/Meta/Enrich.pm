package Krawfish::Koral::Meta::Enrich;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 1;

our %ENRICH_ORDER = (
  'fields'   => 1,
  'snippet'  => 2,
  'termfreq' => 3
);


sub new {
  my $class = shift;
  bless [@_], $class;
};


sub type {
  'enrich';
};


# Get or set operations
sub operations {
  my $self = shift;
  if (@_) {
    if (DEBUG) {
      print_log('kq_enrich', 'Set operations to ' . join(',', map { $_->to_string } @_));
    };
    @{$self} = @_;
    return $self;
  };
  return @$self;
};


# Wrap enrichments in each other
sub wrap {
  my ($self, $query) = @_;

  if (DEBUG) {
    print_log('kq_enrich', 'Wrap operation ' . join(',', @$self));
  };

  foreach ($self->operations) {
    $query = $_->wrap($query);
  };

  return $query;
};


# Normalize aggregations
sub normalize {
  my $self = shift;

  # Sort objects in defined order
  my @ops = sort {
    $ENRICH_ORDER{$a->type} <=> $ENRICH_ORDER{$b->type}
  } @$self;

    # Check for doubles
  for (my $i = 1; $i < @ops; $i++) {

    # Two consecutive operations are identical
    if ($ops[$i]->type eq $ops[$i-1]->type) {

      # Merge fields or values
      if ($ops[$i]->type eq 'fields') {
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
  return 'enrich=[' . join(',', map { $_->to_string } @$self) . ']';
};

1;
