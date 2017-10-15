package Krawfish::Compile::Segment::Aggregate;
use parent 'Krawfish::Compile';
use strict;
use warnings;

use constant DEBUG => 0;

# TODO:
#   It may be better to have one aggregator per match
#   and one aggregator per doc.

# Aggregate values of matches per document and
# per match.

# TODO:
#   See https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations.html

# TODO: Sort all ops for each_match and each_doc support
sub new {
  my $class = shift;
  my $result = {};
  my $self = bless {
    query       => shift,
    ops         => shift,

    last_doc_id => -1,
    collection  => $result,
    last_doc_id => -1,
    finished    => 0
  }, $class;

  # The aggregation needs to trigger on each match
  my (@each_doc, @each_match);
  foreach my $op (@{$self->{ops}}) {
    if ($op->can('each_match')) {
      push @each_match, $op;
    };

    # The aggregation needs to trigger on each doc
    if ($op->can('each_doc')) {
      push @each_doc, $op;
    };
  };

  $self->{each_doc} = \@each_doc;
  $self->{each_match} = \@each_match;

  return $self;
};


sub collection {
  $_[0]->{collection};
};


# TODO:
#   Add collection data to result document
# TODO:
#   Rename to "compilation"
sub collect {
  my ($self, $result) = @_;

  # Add collect
  $result->add_collection($self->collection);

  # Collect result from nested query
  $self->{query}->collect($result);
  return $result;
};


# Iterate to the next result
sub next {
  my $self = shift;

  # Get container object
  my $collection = $self->collection;

  # There is a next match
  # TODO:
  #   If there is no operand per match, only use next_doc
  if ($self->{query}->next) {

    # Get the current posting
    my $current = $self->{query}->current;

    if ($current->doc_id != $self->{last_doc_id}) {

      # Collect data of current operation
      foreach (@{$self->{each_doc}}) {
        $_->each_doc($current, $collection);
      };

      # Set last doc to current doc
      $self->{last_doc_id} = $current->doc_id;
    };

    # Collect data of current operation
    foreach (@{$self->{each_match}}) {
      $_->each_match($current, $collection);
    };

    return 1;
  };

  # Release on_finish event
  unless ($self->{finished}) {
    foreach (@{$self->{ops}}) {
      $_->on_finish($collection);
    };
    $self->{finished} = 1;
  };

  return 0;
};


sub current {
  return $_[0]->{query}->current;
};


sub to_string {
  my $self = shift;
  my $str = 'aggr(';
  $str .= '[' . join(',', map { $_->to_string } @{$self->{ops}}) . ']:';
  $str .= $self->{query}->to_string;
  return $str . ')';
};

# Shorthand for "search through"
sub finalize {
  while ($_[0]->next) {};
  return $_[0];
};

1;
