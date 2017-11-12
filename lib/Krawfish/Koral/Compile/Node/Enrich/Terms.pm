package Krawfish::Koral::Compile::Node::Enrich::Terms;
use Krawfish::Compile::Segment::Enrich::Terms;
use Krawfish::Compile::Segment::Nowhere;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless {
    query => shift,
    nrs => shift
  }, $class;
};

sub to_string {
  my $self = shift;
  return 'terms(' . join(',', @{$self->{nrs}}) .
    ':'. $self->{query}->to_string . ')';
};


# This will identify the query
sub identify {
  my ($self, $dict) = @_;

  $self->{query} = $self->{query}->identify($dict);

  # Fields need to be sorted for the fields API
  return $self;
};


# Materialize query for segment search
sub optimize {
  my ($self, $segment) = @_;

  my $query = $self->{query}->optimize($segment);

  if ($query->max_freq == 0) {
    return Krawfish::Compile::Segment::Nowhere->new;
  };

  return Krawfish::Compile::Segment::Enrich::Terms->new(
    $segment->forward,
    $query,
    $self->{nrs}
  );
};



1;
