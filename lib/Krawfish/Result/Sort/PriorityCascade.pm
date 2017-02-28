package Krawfish::Result::Sort::PriorityCascade;
use Krawfish::Util::PrioritySort;
use Krawfish::Log;
use Data::Dumper;
use strict;
use warnings;

use constant DEBUG => 1;

# TODO:
#   Use Krawfish::Util::PrioritySortPerDoc

# TODO:
#   my $offset = $param{offset};
#   This may however not work in a multi-segment
#   or cluster scenario - so let's forget about it

# TODO:
#   matches in the same document will ALWAYS have duplicate
#   markers, although it does not make sense to lift
#   subsequent fields for them.
#   They should be, probably, stored in identical records!
#   Unless, of course, the sorting happens on the
#   alphabetical level (e.g.)

sub new {
  my $class = shift;
  my %param = @_;

  my $query = $param{query};

  # This is the index element
  my $index  = $param{index};
  my $top_k = $param{top_k};

  # This is the fields element
  # It has the structure [[field], [field, 1]]
  # where the second value is the descending marker
  my $fields = $param{fields};

  # The maximum ranking value may be used
  # by outside filters to know in advance,
  # if a document can't be part of the result set
  my $max_rank_ref;
  if (defined $param{max_rank_ref}) {
    $max_rank_ref = $param{max_rank_ref};
  }
  else {
    my $max_rank = $index->max_rank;
    $max_rank_ref = \$max_rank;
  };

  # Create initial priority queue
  my $queue = Krawfish::Util::PrioritySort->new(
    $self->{top_k},
    $self->{max_rank_ref}
  );

  return bless {
    fields => $fields,
    index => $index,
    top_k => $top_k,
    query => $query,
    queue => $queue,
#    max_rank_ref => $max_rank_ref,
    list => undef,
    pos => -1
  }, $class;
};


sub _init {
  my $self = shift;

  return if $self->{init}++;

  my $query = $self->{query};

  # Get first criterion
  my ($field, $desc) = @{$self->{fields}->[0]};

  # Get ranking
  my $ranking = $fields->ranked_by($field);

  # Get maximum rank if descending order
  my $max = $ranking->max if $desc;

  # Pass through all queries
  while ($query->next) {

    if (DEBUG) {
      print_log('p_sort', 'Get next posting from ' . $query->to_string);
    };

    # Clone record (is that necessary?)
    my $record = $query->current->clone;

    # Fetch rank if doc_id changes
    if ($record->doc_id != $last_doc_id) {

      # Get stored rank
      $rank = $ranking->get($record->doc_id);

      # Revert if maximum rank is set
      $rank = $max - $rank if $max;
    };

    if (DEBUG) {
      print_log('p_sort', 'Rank for doc id ' . $record->doc_id . " is $rank");
    };

    # Insert into priority queue
    $queue->insert($rank, $record);
  };

  # Get the rank reference
  $self->{list} = $queue->reverse_array;
  $self->{length} = $queue->length;
};


sub next {
  my $self = shift;
  $self->_init;

  my $level = 1;
  while ($self->duplicate_rank > 1) {
    my ($field, $desc) = @{$self->{fields}->[$level++]};

    if ($desc) {
      my $ranking = $fields->ranked_by($field);
      my $max = $ranking->max if $desc;

      # TODO:
      #   Reuse the queue with adjusted top_k
      #   and probably sort in-place!
      #   there may be a better in-place
      #   algorithm though
    };
  };

  
  if ($self->{pos}++ < $self->{length}) {
    return 1;
  };
  return;
};


# Return the number of duplicates of the current match
sub duplicate_rank {
  my $self = shift;

  if (DEBUG) {
    print_log('p_sort', 'Check for duplicates from index ' . $self->{pos});
  };

  return $self->{list}->[$self->{pos}]->[1] || 1;
};


1;

__END__


# Init queue
sub _init {
  my $self = shift;

  my $field  = $param{field};
  my $desc = $param{desc} ? 1 : 0;

  
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
    $queue->insert($rank, $record);
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
sub current_sort;


sub to_string {
  my $self = shift;
  my $str = 'prioritySort(';
  $str .= $self->{desc} ? '^' : 'v';
  $str .= ',' . $self->{field} . ':';
  $str .= $self->{query}->to_string;
  return $str . ')';
};


1;
