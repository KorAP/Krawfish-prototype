package Krawfish::Koral::Compile::Node::Group::ClassFrequencies;
use Krawfish::Compile::Segment::Group::ClassFrequencies;
use Krawfish::Util::String qw/squote/;
use Krawfish::Compile::Segment::Nowhere;
use Role::Tiny::With;
use strict;
use warnings;


with 'Krawfish::Koral::Compile::Node::Group';


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
    return Krawfish::Compile::Segment::Nowhere->new;
  };

  return Krawfish::Compile::Segment::Group::ClassFrequencies->new(
    $segment->forward,
    $query,
    $self->{classes}
  );
};

1;
