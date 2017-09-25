package Krawfish::Koral::Meta::Node::Aggregate;
use Krawfish::Meta::Segment::Aggregate;
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


sub optimize {
  my ($self, $segment) = @_;

  my $query = $self->{query}->optimize($segment);


  if ($query->max_freq == 0) {
    return Krawfish::Query::Nowhere->new;
  };

  my $aggr = $self->{aggregates};

  for (my $i = 0; $i < @$aggr; $i++) {

    $aggr->[$i] = $aggr->[$i]->optimize($segment);
  };

  return Krawfish::Meta::Segment::Aggregate->new(
    $query,
    $aggr
  );
};


# Stringification
sub to_string {
  my $self = shift;
  return 'aggr(' .
    join(',', map { $_->to_string } @{$self->{aggregates}}) .
    ':' . $self->{query}->to_string . ')';
};


1;
