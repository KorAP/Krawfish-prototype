package Krawfish::Koral::Compile::Node::Group::Aggregate;
use Krawfish::Compile::Segment::Group::Aggregate;
use Krawfish::Compile::Segment::Nowhere;
use strict;
use warnings;

# EXPERIMENTAL!
# Group aggregations may not be necessary at all!

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
    }
    # else {
    #   TODO:
    #     This should introduce empty aggregations with names as placeholders!
    # }
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
    return Krawfish::Compile::Segment::Nowhere->new;
  };

  # Get all aggregations
  my $aggr = $self->{aggregates};

  # Can't overwrite aggregates because of reoptimization on nodes
  my @aggr;

  # Optimize all aggregation objects
  for (my $i = 0; $i < @$aggr; $i++) {
    push @aggr, $aggr->[$i]->optimize($segment);
  };

  # Set aggregation for group query
  if ($query->does('Krawfish::Compile::Segment::Group')) {
    # Create aggregation query with all aggregations
    $query->aggregation(
      Krawfish::Compile::Segment::Group::Aggregate->new(\@aggr));
  };
  return $query;
};


# Stringification
sub to_string {
  my ($self, $id) = @_;
  return 'gaggr(' .
    join(',', map { $_->to_string($id) } @{$self->{aggregates}}) .
    ':' . $self->{query}->to_string($id) . ')';
};


1;
