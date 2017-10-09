package Krawfish::Compile::Sort::Criterion::Field;
use strict;
use warnings;

warn 'NOT USED YET';

# TODO:
#   The same criterion for K::Result::Node::Field
#   will introduce field fetching etc.

# Constructor
sub new {
  my $self = shift;
  my ($index, $field, $desc) = @_;

  bless {
    field => $field,
    desc => $desc,
    ranking => $index->fields->ranked_by($field),
    max => $self->{ranking}->max if $desc
  }, $class;
};


# Get the rank of the match
sub rank {
  my ($self, $match) = @_;

  # Get rank from match
  my $rank = $self->{ranking}->get($match->doc_id);
  return $self->{max} ? ($self->{max} - $rank) : $rank;
};


# Serialize to string
sub to_string {
  my $self = shift;
  my $str = 'field=';
  $str .= $self->{field};
  $str .= $self->{desc} ? '>' : '<';
  return $str;
};

1;
