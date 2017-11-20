package Krawfish::Compile::Segment::Aggregate;
use Krawfish::Log;
use strict;
use warnings;
use Role::Tiny::With;

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


# Clone object
sub clone {
  my $self = shift;
  my $op_clones = [map { $_->clone } @{$self->operations}];
  __PACKAGE__->new(
    $self->{query}->clone,
    $op_clones
  );
};


# Get operations
sub operations {
  $_[0]->{ops};
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


# stringification
sub to_string {
  my $self = shift;
  my $str = 'aggr(';
  $str .= '[' . join(',', map { $_->to_string } @{$self->{ops}}) . ']:';
  $str .= $self->{query}->to_string;
  return $str . ')';
};


1;
