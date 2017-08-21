package Krawfish::Koral::Meta::Node::Enrich::TermIDs;
use Krawfish::Result::Segment::Enrich::TermIDs;
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
  return 'termids(' . join(',', @{$self->{nrs}}) .
    ':'. $self->{query}->to_string . ')';
};


# This will identify the query and create a list of sorted fields ids
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
    return Krawfish::Query::Nothing->new;
  };

  return Krawfish::Result::Segment::Enrich::TermIDs->new(
    $segment->forward,
    $query,
    $self->{nrs}
  );
};



1;
