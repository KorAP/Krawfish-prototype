package Krawfish::Koral::Meta::Node::Sort;
use Krawfish::Meta::Segment::Sort;
use Krawfish::Query::Nowhere;
use Krawfish::Log;
use strict;
use warnings;

use constant (
  DEBUG => 1,
  UNIQUE => 'id'
);

sub new {
  my $class = shift;

  if (DEBUG) {
    print_log(
      'kq_n_sort', 'Create sort query with ' .
        join(', ', map {$_ ? $_ : '?'} @_)
      );
  };

  return bless {
    query     => shift,
    sort      => shift, # Single sort criterium
    top_k     => shift,
    filter    => shift,
    follow_up => shift  # The query nests a presorted query
  }, $class;
};


sub type {
  'sort';
};


# Get identifiers
sub identify {
  my ($self, $dict) = @_;

  $self->{query} = $self->{query}->identify($dict);

  # Criterion may not exist in dictionary
  if (my $criterion = $self->{sort}->identify($dict)) {
    $self->{sort} = $criterion;
    return $self;
  };

  # Do not sort
  warn 'There is currently no sorting defined';
  return $self->{query};
};


# Stringification
sub to_string {
  my $self = shift;
  my $str = $self->{sort}->to_string;

  if ($self->{top_k}) {
    $str .= ';k=' . $self->{top_k};
  };

  if ($self->{filter}) {
    $str .= ';sortFilter'
  };

  return 'sort(' . $str . ':' . $self->{query}->to_string . ')';
};


# Optimize query for postingslist
sub optimize {
  my ($self, $segment) = @_;

  my $query = $self->{query}->optimize($segment);

  if ($query->max_freq == 0) {
    return Krawfish::Query::Nowhere->new;
  };

  # TODO:
  #   Implement ascending and descending stuff
  return $query;


  # TODO:
  #   unless ($self->{follow_up} && $self->{filter}) {
  #     Apply a dynamic filter if necessary!
  #     $max_rank_ref = ...
  #   }

  # TODO:
  #   This currently only works for fields
  my $ranks;

  my $sort = $self->{sort};
  my $field_ranks = $segment->field_ranks;
  if ($sort->desc) {
    $ranks = $field_ranks->descendig($sort->field->term_id);
  }
  else {
    $ranks = $field_ranks->ascending($sort->field->term_id);
  };

  # TODO:
  #   Return Krawfish::Meta::Segment::Sort::Fine->new;
  #   in case it is a follow up!

  # Return sort object
  return Krawfish::Meta::Segment::Sort->new(
    query     => $query,
    index     => $segment,
    top_k     => $self->{top_k},
    ranks     => $ranks,
    follow_up => $self->{follow_up}
    # max_rank_ref => $max_rank_ref
  );
};

1;
