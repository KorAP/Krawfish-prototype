package Krawfish::Util::PriorityQueue;
use strict;
use warnings;
use Data::Dumper;
use Krawfish::Log;
use POSIX qw/floor/;

# This establishes a priority queue for ranked elements that
# supports equal ranks that can later be sorted based on other criteria.
# This can be used as a first pass sorting - probably simpler than bucket sort:
# http://stackoverflow.com/questions/7272534/finding-the-first-n-largest-elements-in-an-array
#
# The priority queue is based on a simple binary max heap.
#

# TODO:
#   Use Krawfish::Util::Heap as the base heap.


# TODO:
#   See http://lemire.me/blog/2017/06/06/
#     quickly-returning-the-top-k-elements-computer-science-vs-the-real-world/

# TODO:
#   For grouping it may be beneficial to allow witness storing as well,
#   having a method add() that fails, in case the rank is already there.
#
# TODO:
#   Check
#   https://github.com/apache/lucy/blob/62cdcf930dc871fb95b5c99fc86e93afe7a3e344/core/Lucy/Search/HitQueue.c
#   https://github.com/apache/lucy/blob/master/core/Lucy/Util/PriorityQueue.c
#
# Identicals can mean: Have the same rank. It may also mean: Are part of a collection
# with the same rank. For example, multiple matches in a document.
#
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

  if (DEBUG) {
    print_log('prio', 'Initialize new prio');
  };

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
  my ($self, $node) = @_;

  # Rank is beyond useful
  if ($node->[RANK] > ${$self->{max_rank_ref}}) {
    print_log('prio', "Rank is larger than max rank") if DEBUG;
    return;
  };

  return $self->enqueue($node);
};


sub enqueue {
  my ($self, $node) = @_;

  print_log('prio', "Insert with rank " . $node->[RANK]) if DEBUG;

  # Array structure of the queue
  my $array  = $self->{array};
  my $node_i = $self->{index};

  $self->{index}++;

  $array->[$node_i] = $node;

  print_log('prio', "Add new node to index $node_i") if DEBUG;

  my $is_same = 0;

  # Move node to the correct position in the tree
  while ($node_i > 0) {

    # Get parent node
    my $parent_i = _parent_i($node_i);

    # Parent rank is smaller
    if ($array->[$parent_i]->[RANK] < $node->[RANK]) {

      print_log('prio', 'Parent rank ' .
                  $array->[$parent_i]->[RANK] .
                  " is smaller than " . $node->[RANK]) if DEBUG;

      # Swap values
      $self->swap($node_i, $parent_i);
      $node_i = $parent_i;
    }

    # Entry is same
    elsif ($array->[$parent_i]->[RANK] == $node->[RANK]) {

      print_log('prio', "Parent rank " . $node->[RANK] . " is equal") if DEBUG;

      $is_same = 1;
      last;
    }

    # Parent rank is larger
    else {

      print_log('prio', 'Parent rank ' .
                  $array->[$parent_i]->[RANK] .
                  " is greater than " . $node->[RANK]) if DEBUG;

      last;
    };
  };

  if (DEBUG) {
    print_log('prio', 'Tree is ' . $self->to_tree);
  };

  # The rank is identical to the top rank and it's a same
  if ($is_same && $node->[RANK] == ${$self->{max_rank_ref}}) {

    print_log('prio', "Rank is duplicate at top") if DEBUG;

    # SAME is not yet initialized
    if ($array->[0]->[SAME] == 0) {

      # In that case mark all top duplicates
      # Use reference - may as well be passed as a value
      $self->mark_top_duplicates;
    }
    else {
      #   Do incr_top_duplicate($node)
      $self->incr_top_duplicate($node);
      if (DEBUG) {
        print_log('prio', 'Top duplicate value increased');
      };
    }
  };

  # Increment tree node size
  $self->incr($node);

  # Remove top nodes
  if ($self->length >= $self->{top_k}) {

    print_log('prio', "Index has reached top_k") if DEBUG;

    if ($self->length > $self->{top_k}) {

      # Get top identicals

      my $identicals = $self->top_identical_matches;

      if (DEBUG) {
        print_log(
          'prio',
          "First element has $identicals identical matches - by a length of "
            . $self->length . ' and requested k=' . $self->{top_k}
        );
      };

      # The max element exceeds the list now
      if (($self->length - $identicals) >= $self->{top_k}) {
        print_log('prio', 'When removing top, k is still valid') if DEBUG;
        $self->remove_tops($self->top_identical_nodes);
      };
    };

    # Set potentially new maximal ranking value
    ${$self->{max_rank_ref}} = $array->[0]->[RANK];

    if (DEBUG) {
      print_log('prio', 'Tree with length ' . $self->length . ' is ' . $self->to_tree);
      print_log('prio', "New maximum rank is " .$array->[0]->[RANK]);
    };
  };

  return 1;
};




# Increment identicals
sub incr_top_duplicate {
  $_[0]->{array}->[0]->[SAME]++;
};


# Get the top identicals
sub top_identical_matches {
  $_[0]->{array}->[0]->[SAME] || 1;
};

# In this implementation, this is identical to matches
sub top_identical_nodes {
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
# TODO:
#   Rewrite for perdoc
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

  my $temp = $array->[$node_1];
  $array->[$node_1] = $array->[$node_2];
  $array->[$node_2] = $temp;
};


# Mark all duplicates of the top position
sub mark_top_duplicates {
  my $self = shift;

  my $count_same = 0;

  $self->on_same_top(
    0,
    sub { $count_same++ }
  );

  if ($count_same) {
    $self->{array}->[0]->[SAME] = $count_same;
    if (DEBUG) {
      print_log('prio', "Mark top element with count $count_same");
    }
  };
}


# Return tree stringification
sub to_tree {
  my $self = shift;
  return join('', map {
    '[' . $_->[RANK] . ($_->[SAME] ? ':' . $_->[SAME] : '') . ']'
  } @{$self->{array}}[0..$self->{index}-1]);
};


sub incr {};

sub decr {};

# Remove a single top entry
# TODO:
#   Rename to dequeue
sub _remove_single_top {
  my $self = shift;

  # Place the last element in the first position and swap
  my $array = $self->{array};

  # Decrement values
  $self->decr($array->[0]);

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



sub on_same_top {
  my ($self, $node_i, $cb) = @_;
  my $array = $self->{array};
  my $rank = $array->[$node_i]->[RANK];

  $cb->($node_i);

  # Left child
  my $left_i = 2 * $node_i + 1;
  if ($left_i < $self->{index}) {
    if ($array->[$left_i]->[RANK] == $rank) {
      $self->on_same_top($left_i, $cb);
    };

    # Right child
    if (($left_i + 1) < $self->{index}) {
      if ($array->[$left_i+1]->[RANK] == $rank) {
        $self->on_same_top($left_i+1, $cb);
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
