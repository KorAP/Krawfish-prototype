package Krawfish::Result::Sort::PriorityCascade;
use Krawfish::Util::PriorityQueue::PerDoc;
use Krawfish::Posting::Bundle;
use Krawfish::Log;
use Data::Dumper;
use strict;
use warnings;

use constant DEBUG => 0;

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

# TODO:
#   It's possible that fields return a rank of 0, indicating that
#   the field is not yet ranked.
#   In that case these fields have to be looked up, in case they are
#   potentially in the result set (meaning they are ranked before/after
#   the last accepted rank field). If so, they need to be rememembered.
#   After a sort turn, the non-ranked fields are sorted in the ranked
#   fields. The field can be reranked any time.

# TODO:
#   Ranks should respect the ranking mechanism of FieldsRank and
#   TermRank, where only even values are fine and odd values need
#   to be sorted in a separate step.

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

    # Get reference from definition
    $max_rank_ref = $param{max_rank_ref};
  }
  else {

    # Create a new reference
    $max_rank_ref = \(my $max_rank = $index->max_rank);
  };

  # Create initial priority queue
  my $queue = Krawfish::Util::PriorityQueue::PerDoc->new(
    $top_k,
    $max_rank_ref
  );

  # Construct
  return bless {
    fields       => $fields,
    index        => $index,
    top_k        => $top_k,
    query        => $query,
    queue        => $queue,
    max_rank_ref => $max_rank_ref,
    buffer       => Krawfish::Util::Buffer->new,
    pos          => -1
  }, $class;
};


sub _init {
  my $self = shift;

  # Result already initiated
  return if $self->{init}++;

  my $query = $self->{query};

  # Get first sorting criterion
  my ($field, $desc) = @{$self->{fields}->[0]};

  # Get ranking
  my $ranking = $self->{index}->fields->ranked_by($field);

  # Get maximum rank if descending order
  my $max = $ranking->max if $desc;

  # Get maximum accepted rank from queue
  my $max_rank_ref = $self->{max_rank_ref};

  my $last_doc_id = -1;
  my $rank;
  my $queue = $self->{queue};

  # Store the last match buffered
  my $match;

  # Pass through all queries
  while ($match || ($query->next && ($match = $query->current))) {

    if (DEBUG) {
      print_log('p_sort', 'Get next posting from ' . $query->to_string);
    };

    # Get stored rank
    $rank = $ranking->get($match->doc_id);

    # Revert if maximum rank is set
    $rank = $max - $rank if $max;

    if (DEBUG) {
      print_log('p_sort', 'Rank for doc id ' . $match->doc_id . " is $rank");
    };

    # Precheck if the match is relevant
    if ($rank <= $$max_rank_ref) {

      # Create new bundle of matches
      my $bundle = Krawfish::Posting::Bundle->new($match->clone);
      # Remember doc_id
      $last_doc_id = $match->doc_id;
      $match = undef;

      # Iterate over next queries
      while ($query->next) {

        # New match should join the bundle
        if ($query->current->doc_id == $last_doc_id) {

          # Add match to bundle
          $bundle->add($query->current);
        }

        # New match is new
        else {

          # Remember match for the next tome
          $match = $query->current;
          last;
        };
      };

      # Insert into priority queue
      $queue->insert([$rank, 0, $bundle, $bundle->length]) if $bundle;
    }

    # Document is irrelevant
    else {
      $match = undef;
    };
  };

  # Get the rank reference
  # $self->{list} = $queue->reverse_array;
  # $self->{length} = $queue->length;
};


sub next {
  my $self = shift;

  # Initialize query - this will do a full run!
  $self->_init;

  my $level = 1;

  if ($self->{pos} > $self->{top_k}) {
    return;
  };

  my $queue = $self->{queue};

  # IDEA: Push queues on a stack!

  # Get the first element from the identical topics
  if ($queue->top_identical_matches > 1) {

    warn 'Found ' . $queue->top_identical_matches;
#    my ($field, $desc) = @{$self->{fields}->[$level++]};
#
#    if ($desc) {
#      my $ranking = $fields->ranked_by($field);
#      my $max = $ranking->max if $desc;

      # TODO:
      #   Reuse the queue with adjusted top_k
      #   and probably sort in-place!
      #   there may be a better in-place
      #   algorithm though
#    };
  };

#  if ($self->{pos}++ < $self->{length}) {
#    return 1;
#  };
#  return;
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
