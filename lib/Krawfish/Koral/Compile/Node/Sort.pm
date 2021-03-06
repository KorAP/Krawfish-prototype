package Krawfish::Koral::Compile::Node::Sort;
use Krawfish::Compile::Segment::Sort;
use Krawfish::Compile::Segment::SortAfter;
use Krawfish::Compile::Segment::BundleDocs;
use Krawfish::Compile::Segment::Nowhere;
use Krawfish::Log;
use strict;
use warnings;

use constant {
  DEBUG => 0,
  UNIQUE => 'id'
};

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
    criterion => shift,
    top_k     => shift,
    filter    => shift,
    level     => shift
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
  if (my $criterion = $self->{criterion}->identify($dict)) {
    $self->{criterion} = $criterion;
  }
  else {

    # TODO:
    #   This requires a NonSort criterion to add the criterion
    #   plainly. Although the criterion is not available on this node,
    #   it may very well be available in another
    $self->{criterion} = undef;
  };


  return $self;
};


# Optimize query for postingslist
sub optimize {
  my ($self, $segment) = @_;

  if (DEBUG) {
    print_log(
      'kq_n_sort',
      'Optimize query ' . ref($self->{query}) . '=' .
        $self->{query}->to_string
      );
  };

  my $query = $self->{query}->optimize($segment);

  if (DEBUG) {
    print_log('kq_n_sort', 'Optimized query is now ' . ref($query) . '=' .
                $query->to_string);
  };

  if ($query->max_freq == 0) {
    return Krawfish::Compile::Segment::Nowhere->new;
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

  my $criterion = $self->{criterion}->optimize($segment);

  unless ($criterion) {
    print_log('kq_n_sort', 'Sort is not optimizable: ' . $self->{criterion}->to_string);

    # TODO:
    #   In case the field is not defined: Introduce a no-sort-field
    #   Otherwise add a warning before introducing a no-sort field!

    warn 'Do not sort on a non-sortable field!';

    # TODO:
    #   This needs to be checked in identify!
    # warn 'The chosen sort criterion is not a sortable field';
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
  }

  elsif (DEBUG) {
    print_log('kq_n_sort', 'Optimize sort criterion: ' . $criterion->to_string);
  };


  # Bundle documents
  if ($criterion->type eq 'field' && !$self->{level}) {
    $query = Krawfish::Compile::Segment::BundleDocs->new($query);

    # Return sort object
    return Krawfish::Compile::Segment::Sort->new(
      query     => $query,
      segment   => $segment,
      criterion => $criterion,
      top_k     => $self->{top_k},
      # max_rank_ref => $max_rank_ref
    );
  };

  return Krawfish::Compile::Segment::SortAfter->new(
    query     => $query,
    segment   => $segment,
    criterion => $criterion,
    top_k     => $self->{top_k},
    level     => $self->{level}
  );
};



# Stringification
sub to_string {
  my ($self, $id) = @_;
  my $str = $self->{criterion}->to_string($id);

  if ($self->{top_k}) {
    $str .= ';k=' . $self->{top_k};
  };

  if ($self->{filter}) {
    $str .= ';sortFilter'
  };

  return 'sort(' . $str . ':' . $self->{query}->to_string($id) . ')';
};


1;
