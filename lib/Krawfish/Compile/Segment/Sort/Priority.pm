package Krawfish::Compile::Segment::Sort::Priority;
use Krawfish::Util::PriorityQueue;
use Krawfish::Log;
use Data::Dumper;
use strict;
use warnings;

# WARNING!
# THIS IS DEPRECATED IN FAVOR OF Segment::Sort and Segment::SortAfter


use constant DEBUG => 0;

sub new {
  my $class = shift;
  my %param = @_;

  my $query  = $param{query};
  my $fields = $param{fields};
  my $field  = $param{field};
  my $desc   = $param{desc} ? 1 : 0;
  my $top_k  = $param{top_k};

  my $max_rank_ref = $param{max_rank_ref};

  # Create priority queue
  my $queue = Krawfish::Util::PrioritySort->new($top_k, $max_rank_ref);

  return bless {
    field_rank => $fields->ranked_by($field),
    field => $field,
    desc => $desc,
    query => $query,
    queue => $queue,
    list => undef,
    pos => -1
  }, $class;
};


# Init queue
sub _init {
  my $self = shift;

  return if $self->{init}++;

  my $field_rank = $self->{field_rank};

  my $max;
  # Get maximum rank if descending order
  if ($self->{desc}) {
    $max = $field_rank->max;
  };

  my $query = $self->{query};
  my $queue = $self->{queue};
  my $last_doc_id = -1;
  my $rank;

  # Pass through all queries
  while ($query->next) {

    if (DEBUG) {
      print_log('p_sort', 'Get next posting from ' . $query->to_string);
    };

    # Clone record
    my $record = $query->current->clone;

    # Fetch rank if doc_id changes
    if ($record->doc_id != $last_doc_id) {

      # Get stored rank
      $rank = $field_rank->get($record->doc_id);

      # Revert if maximum rank is set
      $rank = $max - $rank if $max;
    };

    if (DEBUG) {
      print_log('p_sort', 'Rank for doc id ' . $record->doc_id . " is $rank");
    };

    # Insert into priority queue
    $queue->insert([$rank, 0, $record]);
  };

  # Get the rank reference
  $self->{list} = $queue->reverse_array;
  $self->{length} = $queue->length;
};


# Get next element from list
sub next {
  my $self = shift;
  $self->_init;
  if ($self->{pos}++ < $self->{length}) {
    return 1;
  };
  return;
};


# Get current element
sub current {
  my $self = shift;

  # 2 is the index of the value
  if (DEBUG) {
    print_log('p_sort', 'Get match from index ' . $self->{pos});
  };

  return $self->{list}->[$self->{pos}]->[2];
};


# Return the number of duplicates of the current match
sub duplicate_rank {
  my $self = shift;

  if (DEBUG) {
    print_log('p_sort', 'Check for duplicates from index ' . $self->{pos});
  };

  return $self->{list}->[$self->{pos}]->[1] || 1;
};


# This returns an additional data structure with key/value pairs
# in sorted order to document the sort criteria.
# Like: [[class_1 => 'cba'], [author => 'Goethe']]...
# This is necessary for the cluster-merge-sort
sub current_sort {
  ...
};


sub to_string {
  my $self = shift;
  my $str = 'prioritySort(';
  $str .= $self->{desc} ? '^' : 'v';
  $str .= ',' . $self->{field} . ':';
  $str .= $self->{query}->to_string;
  return $str . ')';
};


1;
