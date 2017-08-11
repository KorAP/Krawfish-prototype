package Krawfish::Koral::Meta::Node::Aggregate::Length;
use Krawfish::Result::Segment::Aggregate::Length;
#use Krawfish::Util::String qw/squote/;
use Krawfish::Query::Nothing;
use strict;
use warnings;


warn 'DEPRECATED';

# Create new enrichment object for fields
sub new {
  my $class = shift;
  my $self = '';
  bless \$self, $class;
};


sub to_string {
  'length';
};


# This will identify the query and create a list of sorted fields ids
sub identify {

  warn 'DEPRECATED';

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

  return Krawfish::Result::Segment::Aggregate::Length->new(
    $segment,
    $query
  );
};

1;
