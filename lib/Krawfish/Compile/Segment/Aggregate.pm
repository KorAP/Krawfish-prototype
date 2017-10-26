package Krawfish::Compile::Segment::Aggregate;
use parent 'Krawfish::Compile';
use strict;
use warnings;

use constant DEBUG => 0;

# Aggregate values of matches per document and
# per match.

# TODO:
#   See https://www.elastic.co/guide/en/
#     elasticsearch/reference/current/
#     search-aggregations.html

sub new {
  my $class = shift;

  my $self = bless {
    query => shift,
    ops   => shift,
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

  $self->{each_doc}   = \@each_doc;
  $self->{each_match} = \@each_match;

  return $self;
};


# Return the result of all ops
sub compile {
  my $self = shift;

  # Get result object
  my $result = $self->result;

  # Add all results
  while ($self->next) {
    $result->add_match($self->current_match);
  };

  # Add aggregations to result
  foreach (@{$self->{ops}}) {
    $result->add_aggregation($_->result);
  };

  # Collect more data
  my $query = $self->{query};
  if ($query->isa('Krawfish::Compile')) {
    $query->result($result)->compile;
  };

  return $result;
};



# Iterate to the next result
sub next {
  my $self = shift;

  # There is a next match
  # TODO:
  #   If there is no operand per match,
  #   only use next_doc
  if ($self->{query}->next) {

    # Get the current posting
    my $current = $self->{query}->current;

    if ($current->doc_id != $self->{last_doc_id}) {

      # Collect data of current operation
      foreach (@{$self->{each_doc}}) {
        $_->each_doc($current);
      };

      # Set last doc to current doc
      $self->{last_doc_id} = $current->doc_id;
    };

    # Collect data of current operation
    foreach (@{$self->{each_match}}) {
      $_->each_match($current);
    };

    return 1;
  };

  # Release on_finish event
  unless ($self->{finished}) {

    foreach (@{$self->{ops}}) {
      $_->result->on_finish;
      # $_->on_finish($collection);
    };
    $self->{finished} = 1;
  };

  return 0;
};


# Shorthand for "search through"
sub finalize {
  while ($_[0]->next) {};
  return $_[0];
};


# Get current posting
sub current {
  return $_[0]->{query}->current;
};


# stringification
sub to_string {
  my $self = shift;
  my $str = 'aggr(';
  $str .= '[' . join(',', map { $_->to_string } @{$self->{ops}}) . ']:';
  $str .= $self->{query}->to_string;
  return $str . ')';
};


1;
