package Krawfish::Compile::Segment::Aggregate;
use Krawfish::Log;
use strict;
use warnings;
use Role::Tiny;

with 'Krawfish::Compile';

use constant DEBUG => 0;

# Aggregate values of matches per document and
# per match.

# TODO:
#   It may be necessary to introduce an "AggregateOnCorpus"
#   mechanism, that first wraps the corpus before filtering.
#   This - however - will require the corpus being referenced
#   so aggregation is not done multiple times.
#   This is necessary, e.g., to aggregate the number of tokens
#   in a corpus independent of the matches in this corpus.
#   A value, relevant to compute t-score or mi.
#   See http://lingua.mtsu.edu/chinese-computing/docs/tscore.html

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

  if (DEBUG) {
    print_log('aggr', 'Compile aggregation');
  };

  # Get result object
  my $result = $self->result;

  # Add all results
  while ($self->next) {
    if (DEBUG) {
      print_log(
        'aggr',
        'Add match ' . $self->current_match->to_string
      );
    };

    $result->add_match($self->current_match);
  };

  # Add aggregations to result
  foreach (@{$self->{ops}}) {
    if (DEBUG) {
      print_log(
        'aggr',
        'Add result to aggr ' . $_->result
      );
    };
    $result->add_aggregation($_->result);
  };

  # Collect more data
  my $query = $self->{query};
  if ($query->isa('Krawfish::Compile')) {
    $query->result($result)->compile;
  };

  if (DEBUG) {
    print_log(
      'aggr',
      'Result is ' . $result
    );
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
    };
    $self->{finished} = 1;
  };

  return 0;
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
