package Krawfish::Koral::Compile::Node::Aggregate;
use Krawfish::Compile::Segment::Aggregate;
use Krawfish::Query::Nowhere;
use strict;
use warnings;

# TODO:
#   Identify() should probably first return a Segment::Aggregate object

sub new {
  my $class = shift;
  bless {
    query => shift,
    aggregates => shift
  }, $class;
};


# Aggregation
sub identify {
  my ($self, $dict) = @_;

  my @identifier;
  foreach (@{$self->{aggregates}}) {

    # Field may not exist in dictionary
    my $aggr = $_->identify($dict);
    if ($aggr) {
      push @identifier, $aggr;
    };
  };

  # Identify the query
  $self->{query} = $self->{query}->identify($dict);

  # Do not return any fields
  return $self->{query} if @identifier == 0;

  $self->{aggregates} = \@identifier;

  return $self;
};


# Optimize aggregation query
sub optimize {
  my ($self, $segment) = @_;

  my $query = $self->{query}->optimize($segment);

  # There is nothing to query - return nothing
  # TODO:
  #   It may be required to have some default
  #   null-values for aggregation that need to
  #   be returned.
  if ($query->max_freq == 0) {
    return Krawfish::Query::Nowhere->new;
  };

  # Get all aggregations
  my $aggr = $self->{aggregates};

  # Optimize all aggregation objects
  for (my $i = 0; $i < @$aggr; $i++) {
    $aggr->[$i] = $aggr->[$i]->optimize($segment);
  };

  # Create aggregation query with all aggregations
  return Krawfish::Compile::Segment::Aggregate->new(
    $query,
    $aggr
  );
};


# Stringification
sub to_string {
  my ($self, $id) = @_;
  return 'aggr(' .
    join(',', map { $_->to_string($id) } @{$self->{aggregates}}) .
    ':' . $self->{query}->to_string($id) . ')';
};


1;
