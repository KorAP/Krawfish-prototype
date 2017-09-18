package Krawfish::Koral::Meta::Node::Group::ClassFrequencies;
use Krawfish::Result::Segment::Group::ClassFrequencies;
use Krawfish::Util::String qw/squote/;
use Krawfish::Query::Nothing;
use strict;
use warnings;


# Create new enrichment object for fields
sub new {
  my $class = shift;
  bless {
    query => shift,
    classes => shift
  }, $class;
};


sub to_string {
  my $self = shift;
  return 'gClassFreq(' . join(',', @{$self->{classes}}) .
    ':' . $self->{query}->to_string . ')';
};


# This will identify the query and create a list of sorted fields ids
sub identify {
  my ($self, $dict) = @_;
  $self->{query} = $self->{query}->identify($dict);
  return $self;
};


# Materialize query for segment search
sub optimize {
  my ($self, $segment) = @_;

  my $query = $self->{query}->optimize($segment);

  if ($query->max_freq == 0) {
    return Krawfish::Query::Nothing->new;
  };

  return Krawfish::Result::Segment::Group::ClassFrequencies->new(
    $segment->forward,
    $query,
    $self->{classes}
  );
};

1;
