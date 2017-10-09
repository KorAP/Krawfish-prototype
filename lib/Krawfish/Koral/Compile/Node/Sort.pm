package Krawfish::Koral::Compile::Node::Sort;
use Krawfish::Compile::Segment::Sort;
use Krawfish::Compile::Segment::SortAfter;
use Krawfish::Compile::Segment::BundleDocs;
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
  }
  else {

    # TODO:
    #   This requires a NonSort criterion to add the criterion
    #   plainly. Although the criterion is not available on this node,
    #   it may very well be available in another
    $self->{sort} = undef;
  };


  return $self;
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

  # TODO:
  #   unless ($self->{follow_up} && $self->{filter}) {
  #     Apply a dynamic filter if necessary!
  #     $max_rank_ref = ...
  #   }

  # TODO:
  #   This currently only works for fields

  # TODO:
  #   Optimize the sort criterion and don't pass ranks!
  #   The sort criterion should provide an API to the ranking
  #   with ->rank_for()

  my $sort = $self->{sort}->optimize($segment);

  unless ($sort) {

    # TODO:
    #   This needs to be checked in identify!
    warn 'The chosen sort criterion is not a sortable field';
    return $self->{query} unless $self->{follow_up};

    # TODO:
    #   !!!!
    #   This is wrong! the query then needs to be nested in
    #   a non-follow up query - so it might be better to check
    #   based on the nested query if the current query is a follow up or not!
    #
    #   It's also important to remember that although in this segment/node
    #   this sorting criterion is irrelevant, in another segment/node
    #   the sorting criterion may very well be important, so a NoSort-query
    #   also needs to add the query criterion!
    return $self->{query};
  };

  # TODO:
  #   Return Krawfish::Compile::Segment::Sort::Fine->new;
  #   in case it is a follow up!
  # follow_up => $self->{follow_up}

  # Bundle documents
  if ($sort->type eq 'field' && !$self->{follow_up}) {
    $query = Krawfish::Compile::Segment::BundleDocs->new($query);

    # Return sort object
    return Krawfish::Compile::Segment::Sort->new(
      query     => $query,
      segment   => $segment,
      sort      => $sort,
      top_k     => $self->{top_k},
      # max_rank_ref => $max_rank_ref
    );
  };

  return Krawfish::Compile::Segment::SortAfter->new(
    query     => $query,
    segment   => $segment,
    sort      => $sort,
    top_k     => $self->{top_k},
  );
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


1;
