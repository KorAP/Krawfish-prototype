package Krawfish::Koral::Compile::Node::Group::Fields;
use Krawfish::Compile::Segment::Group::Fields;
use Krawfish::Util::String qw/squote/;
use Krawfish::Compile::Segment::Nowhere;
use strict;
use warnings;


# Create new enrichment object for fields
sub new {
  my $class = shift;
  bless {
    query => shift,
    fields => shift
  }, $class;
};


sub to_string {
  my ($self, $id) = @_;
  return 'gFields(' . join(',', map { $_->to_string($id) } @{$self->{fields}}) .
    ':' . $self->{query}->to_string($id) . ')';
};


# This will identify the query and create a list of sorted fields ids
sub identify {
  my ($self, $dict) = @_;

  my @identifier;
  foreach (@{$self->{fields}}) {

    # Field may not exist in dictionary
    my $field = $_->identify($dict);

    # Field is known
    if ($field) {
      push @identifier, $field;
    }

    # Field is unknown
    else {
      push @identifier, $_;
    };
  };

  $self->{query} = $self->{query}->identify($dict);

  # Do not return any fields
  return $self->{query} if @identifier == 0;

  # Fields need to be sorted for the fields API
  $self->{fields} = [sort { $a->term_id <=> $b->term_id }  @identifier];

  return $self;
};


# Materialize query
#sub term_ids {
#  my $self = shift;
#  return [map { $_->term_id } @{$self->{fields}}];
#};


# Materialize query for segment search
sub optimize {
  my ($self, $segment) = @_;

  my $query = $self->{query}->optimize($segment);

  if ($query->max_freq == 0) {
    return Krawfish::Compile::Segment::Nowhere->new;
  };

  return Krawfish::Compile::Segment::Group::Fields->new(
    $segment->fields,
    $query,
    $self->{fields} # $self->term_ids
  );
};

1;
