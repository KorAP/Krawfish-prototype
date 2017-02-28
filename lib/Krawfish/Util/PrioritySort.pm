package Krawfish::Util::PrioritySort;
use strict;
use warnings;
use Data::Dumper;
use Krawfish::Log;
use POSIX qw/floor/;

# TODO: use enqueue and dequeue

# This establishes a priority queue for ranked elements that
# supports equal ranks that can later be sorted based on other criteria.
# This can be used as a first pass sorting - probably simpler than bucket sort:
# http://stackoverflow.com/questions/7272534/finding-the-first-n-largest-elements-in-an-array
#
# The priority queue is based on a simple binary max heap.
#
# TODO:
#   Create a variant, that keeps a separated count for
#   "matches_in_doc", so matches in the same document only
#   have one node and need to be ranked only once.
#
# TODO:
#   For grouping it may be beneficial to allow witness storing as well,
#   having a method add() that fails, in case the rank is already there.
#
# TODO:
#   Potentially use a faster heap variant
#
# TODO:
#   Check
#   https://github.com/apache/lucy/blob/62cdcf930dc871fb95b5c99fc86e93afe7a3e344/core/Lucy/Search/HitQueue.c
#   https://github.com/apache/lucy/blob/master/core/Lucy/Util/PriorityQueue.c

use constant {
  DEBUG => 0,
  RANK  => 0,
  SAME  => 1, # 0 means: not checked yet!
  VALUE => 2
};


# Construct new HEAP structure
sub new {
  my $class = shift;
  my ($top_k, $max_rank_ref) = @_;
  bless {
    top_k        => $top_k,
    max_rank_ref => $max_rank_ref,
    array        => [],
    index        => 0
  }, $class;
};


# Insert node to the heap
# Each node in the priority queue has the following values:
# [rank, same, value]
# The SAME value is either 0 (unknown), 1 initialized,
# or larger (2 means there are 2 identical ranks etc.)
sub insert {
  my ($self, $rank, $value) = @_;

  print_log('prio', "Insert with rank $rank") if DEBUG;

  # Rank is beyond useful
  if ($rank > ${$self->{max_rank_ref}}) {
    print_log('prio', "Rank is larger than max rank") if DEBUG;
    return;
  };

  # Array structure of the queue
  my $array  = $self->{array};
  my $node_i = $self->{index};

  $self->{index}++;

  $array->[$node_i] = [$rank, 0, $value];

  print_log('prio', "Add new node to index $node_i") if DEBUG;

  my $is_same = 0;

  # Move node to the correct position in the tree
  while ($node_i > 0) {

    # Get parent node
    my $parent_i = _parent_i($node_i);

    # Parent rank is smaller
    if ($array->[$parent_i]->[RANK] < $rank) {

      print_log('prio', 'Parent rank ' .
                  $array->[$parent_i]->[RANK] .
                  " is smaller than $rank") if DEBUG;

      # Swap values
      $self->swap($node_i, $parent_i);
      $node_i = $parent_i;
    }

    # Entry is same
    elsif ($array->[$parent_i]->[RANK] == $rank) {

      print_log('prio', "Parent rank $rank is equal") if DEBUG;

      $is_same = 1;
      last;
    }

    # Parent rank is larger
    else {

      print_log('prio', 'Parent rank ' .
                  $array->[$parent_i]->[RANK] .
                  " is greater than $rank") if DEBUG;

      last;
    };
  };

  print_log('prio', 'Tree is ' . $self->to_tree) if DEBUG;

  # The rank is identical to the top rank and it's a same
  if ($is_same && $rank == ${$self->{max_rank_ref}}) {

    print_log('prio', "Rank is duplicate at top") if DEBUG;

    # Increment same value - although it may not
    # yet be initialized

    # TODO:
    #   Do incr_top_duplicate($node)
    if ($array->[0]->[SAME]++ == 0) {

      # In that case mark all top duplicates
      # Use reference - may as well be passed as a value
      $self->mark_top_duplicates;
    }

    elsif (DEBUG) {
      print_log('prio', 'Top duplicate value increased');
    };
  };

  # Remove top nodes
  if ($self->length >= $self->{top_k}) {

    print_log('prio', "Index has reached top_k") if DEBUG;

    if ($self->length > $self->{top_k}) {

      # Get top identicals

      my $same = $self->top_identicals;

      if (DEBUG) {
        print_log(
          'prio',
          "First element has $same identicals - by a length of " . $self->length .
            ' and requested k=' . $self->{top_k}
        );
      };

      # The max element exceeds the list now
      if (($self->length - $same) >= $self->{top_k}) {
        print_log('prio', 'When removing top, k is still valid') if DEBUG;
        $self->remove_tops($same);
      };
    };

    # Set potentially new maximal ranking value
    ${$self->{max_rank_ref}} = $array->[0]->[RANK];

    if (DEBUG) {
      print_log('prio', 'Tree is ' . $self->to_tree);
      print_log('prio', "New maximum rank is " .$array->[0]->[RANK]);
    };
  };

  return 1;
};

# Get the top identicals
sub top_identicals {
  $_[0]->{array}->[0]->[SAME] || 1;
};


# Get the maximum rank
sub max_rank {
  ${$_[0]->{max_rank_ref}};
};


# Get the length of the queue
sub length {
  $_[0]->{index};
};


# This will convert the max-heap destructible
# to a min-first array in-place
# TODO:
#   This should work with nodes!
sub reverse_array {
  my $self = shift;

  print_log('prio', 'Reverse array in-place') if DEBUG;

  # Get array
  my $array = $self->{array};

  my ($rank, $duplicates) = (0, 0);
  my $temp;
  my $length = $self->{index} - 1;

  # Get the next bottom node until list is at the end
  for (my $i = $length; $i >= 0; $i--) {

    print_log(
      'prio',
      '> Add value of rank ' .
        $array->[0]->[RANK] .
        ' to array at index ' .
        $i
      ) if DEBUG;

    # Copy value
    $temp = $array->[0];

    # If the rank is identical - add to duplicates
    if ($rank == $array->[0]->[RANK]) {
      $duplicates++;
    }
    else {

      # there are duplicates
      if ($duplicates) {
        $array->[$i+1]->[SAME] = $duplicates + 1;
        $duplicates = 0;
      };

      # remember rank
      $rank = $array->[0]->[RANK];
    };

    # Remove top
    $self->_remove_single_top;

    $array->[$i] = $temp;
    $array->[$i]->[SAME] = 0;
  };

  if ($duplicates) {
    $array->[0]->[SAME] = $duplicates + 1;
  };

  $#{$self->{array}} = $length;
  $self->{index} = $length;
  return $self->{array};
};


# Remove the top X elements from the heap
sub remove_tops {
  my ($self, $same) = @_;

  print_log('prio', "Remove top nodes") if DEBUG;

  my $array = $self->{array};

  print_log('prio', "There are $same top nodes to delete") if DEBUG;

  # Remove all tops - one after the other
  # This is probably slow and could be optimized!
  $self->_remove_single_top for 1 .. $same;

  # It's possible to have a situation like
  #
  #   30        5        20
  #   / \  ->  / \  ->  / \
  #  20 20    20 20    20  5
  #
  # which means that again a duplicate without
  # counts is on top!

  # Check duplicates of the new top node
  $self->mark_top_duplicates;
};


# Swap two indices
sub swap {
  my ($self, $node_1, $node_2) = @_;
  my $array = $self->{array};

  print_log('prio', "Swap indices $node_1 and $node_2") if DEBUG;

  # TODO:
  #   There may be a directive!
  my $temp = $array->[$node_1];
  $array->[$node_1] = $array->[$node_2];
  $array->[$node_2] = $temp;
};


# Mark all duplicates of the top position
sub mark_top_duplicates {
  my $self = shift;

  my $top_node = $self->{array}->[0];
  my $count_ref = 0;
  $self->_sum_same(
    0,
    $top_node->[RANK],
    \$count_ref
  );
  if ($count_ref) {
    $top_node->[SAME] = $count_ref;
    if (DEBUG) {
      print_log('prio', "Mark top element with count " . ($count_ref));
    }
  };
};


# Return tree stringification
sub to_tree {
  my $self = shift;
  return join('', map {
    '[' . $_->[RANK] . ($_->[SAME] ? ':' . $_->[SAME] : '') . ']'
  } @{$self->{array}}[0..$self->{index}-1]);
};


# Remove a single top entry
sub _remove_single_top {
  my $self = shift;

  # Place the last element in the first position and swap
  my $array = $self->{array};

  $array->[0] = $array->[--$self->{index}];

  print_log('prio', 'Move last entry ' . $array->[0]->[RANK] . ' to top node') if DEBUG;

  # Go down
  my $node_i = 0;
  my $child_i;

  # Check the maximum child
  while (($child_i = $self->_max_child_i($node_i))) {

    print_log('prio', "Node has a child - and the max child index is $child_i") if DEBUG;

    # The child is larger than the current rank
    if ($array->[$child_i]->[RANK] > $array->[$node_i]->[RANK]) {
      print_log('prio',
                'The child has a bigger rank: ' .
                  $array->[$child_i]->[RANK] .
                  ' vs. ' .
                  $array->[$node_i]->[RANK]
                ) if DEBUG;
      $self->swap($node_i, $child_i);
      $node_i = $child_i;
      print_log('prio', "New node index is $node_i") if DEBUG;
    }
    else {
      last;
    };
  };
};


# Sum up all duplicates
sub _sum_same {
  my ($self, $node_i, $rank, $count_ref) = @_;

  my $array = $self->{array};

  print_log('prio', "Found node with rank $rank at index $node_i") if DEBUG;

  # Increment duplicate count
  $$count_ref++;

  # Left child
  my $left_i = 2 * $node_i + 1;
  if ($left_i < $self->{index}) {
    if ($array->[$left_i]->[RANK] == $rank) {
      $self->_sum_same($left_i, $rank, $count_ref);
    };

    # Right child
    if (($left_i + 1) < $self->{index}) {
      if ($array->[$left_i+1]->[RANK] == $rank) {
        $self->_sum_same($left_i+1, $rank, $count_ref);
      };
    };
  };
};


# Get index of maximum child
sub _max_child_i {
  my ($self, $node_i) = @_;
  my $array = $self->{array};

  my $left_i  = 2 * $node_i + 1;

  print_log('prio', 'Check for larger child') if DEBUG;

  # Both indices are given
  if ($left_i < $self->{index}) {
    return $array->[$left_i]->[RANK] > $array->[$left_i + 1]->[RANK] ? $left_i : $left_i + 1;
  }

  # Left child is larger
  elsif ($left_i == $self->{index}) {
    return $left_i;
  };

  print_log('prio', 'No child') if DEBUG;

  # No child
  return 0;
};


# Calculate parent index
sub _parent_i ($) {
  floor(($_[0] - 1) / 2);
};


1;
