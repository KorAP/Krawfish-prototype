package Krawfish::Index::Store::V1::Dictionary;
use Krawfish::Log;
use strict;
use warnings;
use Memoize;
use POSIX qw/floor/;

# This is necessary to deal with the dynamic structure
use constant {
  SPLIT_CHAR => 0,
  LO_KID     => 1,
  EQ_KID     => 2,
  HI_KID     => 3,
  TERM_ID    => 4,
  TERM_CHAR  => '00',
  DEBUG      => 0
};

# TODO:
#   It's probably WAY simpler to just store the values in alphabetic
#   order and use a binary search on it instead of doing binary tree search.
#   This will also simplify merge().
#   AND
#   Use linear search for small arrays, see
#   https://schani.wordpress.com/2010/04/30/linear-vs-binary-search/

# TODO:
#   - The datastructure should be rather like:
#     (([LENGTH-first-bit-not-set][xor][char])|([xor-first-bit-set][char]))*
#     Because then there is no need for length-1 information.
#     It may also be beneficial to have the information of a leaf node
#     directly encoded in the xor, though this may be complicated,
#     leaving only 30bit for xor
#   - Characters are stored as UTF-32

# TODO:
#   - Benchmark deep first organization in favor of breadth-first!
#     It may be beneficial to go deep-first on retrieval because of cache-
#     prefetching (so a string with a linked list at the end is probably
#     in the same page completely!)

# This is a very compact representation of a Ternary Search Tree.
# On each letter node, the binary search tree is complete and stored
# in an array. The parental relation is implemented using a
# xor-double-link on the character equality pointer to make reverse retrieval
# on term_ids simple.
# By storing the tree in a byte array with the structure
# ([long:length][long:char][long:xor/term_id])*
# the dictionary can be loaded fast with minimal footprint on memory.

# In a complete BST, the children are
# identifiably by
# - 2 * node_i + 1 and
# - 2 * node_i + 2
# The parent is identifiable by
# - floor($node_i - 1) / 2

# TODO: Support collations
# - https://msdn.microsoft.com/en-us/library/ms143726.aspx
# - http://userguide.icu-project.org/collation


# from_array
sub new {
  my $class = shift;
  bless [
    [@_],
    [] # term index
  ], $class;
};


# Pass a dynamic TST
sub from_dynamic {
  my $class = shift;
  my $dynamic = shift;
  bless [convert_to_array($dynamic)], $class;
};


# read with header
# This may first be done in the parent dictionary module
# and then be delegated to the right version
sub from_file;


# write a header
sub to_file;


# Search for string
# TODO:
#   Support collation my $diff = collation_cmp($char, $node_char);
sub search {
  my ($self, $str) = @_;
  my @char = (split(//, $str), TERM_CHAR);

  # Root node
  my $pos = 0;

  my $array = $self->[0];

  # Length of the root bst
  # Length (e.g. 4 bytes char + 4 bytes xor)
  my $length = $array->[$pos] * 2;
  my $node_i = 1;
  my $node_char;
  my $i = 0;

  # Character at node position
  while ($node_char = $array->[$pos + $node_i]) {

    # Check for right child
    my $char = $char[$i] or return;

    print_log('v1_dict', "$char vs $node_char") if DEBUG;

    # Check for right child
    if ($char lt $node_char) {
      print_log('v1_dict', "$char < $node_char") if DEBUG;

      # Move to left child
      # pos is the ternary node offset, 1 is the length
      $node_i = lo_kid($node_i);
    }

    # Check for left child
    elsif ($char gt $node_char) {
      print_log('v1_dict', "$char > $node_char") if DEBUG;

      # Move to right child
      # pos is the ternary node offset, 1 is the intermediate xor
      $node_i = hi_kid($node_i);
    }

    # Follow the transition
    else {

      # Get eq node and xor the result
      $pos = $array->[$pos + $node_i + 1] ^ $pos;

      if (DEBUG) {
        print_log('v1_dict', "$char == $node_char");
        print_log('v1_dict', "xor-node is $pos");
      };

      if ($char eq TERM_CHAR) {
        print_log('v1_dict', "Found term_id $pos for $str") if DEBUG;
        return $pos;
      };

      # Move eq-node
      print_log('v1_dict', "Next node is at offset $pos") if DEBUG;

      # Get the length of the BST
      $length = $array->[$pos] * 2;

      # Get the root node offset
      $node_i = 1;
      $i++;
      next;
    };

    # No right child available
    return if $node_i > ($length + $pos);
  };
  undef;
};


sub lo_kid ($) {
  2 * $_[0] + 1
};

sub hi_kid ($) {
  2 * $_[0] + 3
};


sub search_case_insensitive;

sub search_diacritic_insensitive;

sub search_approximative;

sub search_regex;

# Merge static tree with dynamic tree
sub merge;

# Return iterator of term ids
# TODO:
#   Be aware, this is only in collation
#   order of the insertion, that may not be very helpful.
sub in_prefix_order;

sub in_suffix_order;


# Store the TST with complete binary search trees at each
# character level and XOR chains from eq to root node and next node
# to make bidirectional vertical traversal simple
sub convert_to_array {
  # TODO:
  #   - Sort all nodes in complete level sort order
  #   - Use a stack or something similar to store the info and
  #     keep next/previous-diff-xor for the eq nodes.
  #   - All characters need to be treated as UCS2 (2-byte encoding)
  #     or utf-32 (4-byte encoding)
  my $dynamic_node = shift;

  # Init with the first offset
  my $parent_offset  = 0;
  my $node_offset    = 0;
  my $curr_offset    = 0;
  my $gparent_offset = 0;

  # Iterate over the tree breadth-first
  # TODO:
  #   It may be better to store depth-first,
  #   so vertical nodes may be closer to each other,
  #   meaning the deltas to xor are smaller.
  #   In that case unique suffixes are stored in one page,
  #   which may be faster.
  #
  my @queue = ([$node_offset, $parent_offset, $dynamic_node, $gparent_offset]);
  my @array = ();
  my @term_ids = ();

  my $parent_of_bst = 0;

  # Iterate in a breadth-first manner
  while (scalar(@queue) > 0) {

    # Get offset information
    # - The node offset is the position of the parent pointer
    # - The offset is the position of the parent root
    ($node_offset, $parent_offset, $dynamic_node, $gparent_offset) = @{shift @queue};

    # Get the current letter node as an array
    my ($length, $chars) = _complete_level_sort($dynamic_node);

    # The next node array starts with a length indicator
    push @array, $length;

    # The current root position
    $curr_offset = $#array;

    # Fix the parent nodes xor-eq-value
    if ($parent_offset > 0) {

      if (DEBUG) {
        # print_log('v1_dict', "The current bst parent is $parent_of_bst") if DEBUG;

        print_log('v1_dict', "Fix the current parent eq node");
        print_log('v1_dict',
                  '  ' . $array[$parent_offset - 1] .
                    " at $node_offset/$curr_offset with $gparent_offset:     " .
                    $gparent_offset .
                    " xor $parent_offset = " .
                    ($gparent_offset ^ $parent_offset),
          );
      };

      # TODO:
      $array[$parent_offset] ^= $curr_offset; # = $curr_offset
    }

    elsif (DEBUG) {
      print_log(
        'v1_dict',
        "curr_offset is $curr_offset with parent_offset = $parent_offset"
      );
    };

    foreach (@$chars) {

      # Push node values and eq-xor-pointers to array.
      # The eq-xor-pointer is initially treated as a mirror,
      # as if the node is a leaf node
      push @array, (
        # encode("UCS-2LE", $_->[SPLIT_CHAR]),
        $_->[SPLIT_CHAR]
      );

      # TODO:
      #   Final transitions store a link to the term_id/pos in their eq
      #   This is a final stream (may be separate from @array), that supports
      #   O(1) for term id request and O(n) for term retrieval
      if ($_->[SPLIT_CHAR] eq TERM_CHAR) {
        # push @array, $parent_offset ^ $_->[TERM_ID]; #

        push @array, $curr_offset ^ $_->[TERM_ID];

        # store leaf node in term_id array
        $term_ids[$_->[TERM_ID]] = $#array;
      }
      # Push temporary eq
      else {
        #        push @array, $parent_offset; # $curr_offset;
        # It's rather initialized 0 ^ $curr_offset
        push @array, $curr_offset; # It's rather initialized 0 ^ $curr_offset

        # Push the current EQ node on the queue
        push @queue, [$curr_offset, $#array, $_->[EQ_KID], $parent_offset];
      };
    };

    $parent_of_bst = $curr_offset;
  };

  return \@array, \@term_ids;
};


sub to_string {
  my $self = shift;
  my $marker = shift // 101;
  my @array = @{$self->[0]}[0..100];
  @array = grep { $_ } @array;

  my $i = 0;
  @array = map { $i++ == $marker ? "[$marker:$_]" : $_ } @array;
  '<' . join(',', @array) . '>';
};


sub term_by_term_id {
  my ($self, $term_id) = @_;

  # TODO:
  #   Check that term_id is < max_term_id

  my ($array, $term_ids) = ($self->[0], $self->[1]);

  # Get the leaf node
  my $pos = $term_ids->[$term_id];
  my $curr_offset = $array->[$pos];

  my $parent_i = $curr_offset ^ $term_id;

  if (DEBUG) {
    print_log(
      'v1_dict',
      "Leave node position of $term_id is $pos with first eq $curr_offset",
      "Parent node is at offset $parent_i"
    );
  };

  return;

  my $parent_char = $array->[$parent_i + 1];

  print_log('v1_dict', "First parent is $parent_char") if DEBUG;


  my @chars;

  my ($eq);


  my $i = 0;
  while ($eq) {
    warn $array->[$eq];

    # Add char at the end of the string
    unshift @chars, $array->[$eq-1];
    $eq = $array->[$eq] ^ $eq;
    last if $i++ > 10;
  };

  return join '', @chars;
};


# Traverse the current level tree in-order to
# get nodes in alphabetic order
sub _in_order {
  my $dynamic_node = shift;

  my @stack = ();
  my @results = ();
  my $length = 0;

  while (scalar(@stack) != 0 || $dynamic_node->[SPLIT_CHAR]) {

    if ($dynamic_node->[SPLIT_CHAR]) {
      push @stack, $dynamic_node;
      $dynamic_node = $dynamic_node->[LO_KID];
    }

    else {
      $dynamic_node = pop @stack;
      push @results, $dynamic_node;
      $length++;
      $dynamic_node = $dynamic_node->[HI_KID];
    };
  };

  return ($length, \@results);
};


# THE REST IS NOT NECESSARY WHEN STORING IN ALPHABETIC ORDER
# FOR BINARY SEARCH OR SEQUENTIAL SEARCH


# Sort the nodes to create
# a complete binary search tree
# see http://stackoverflow.com/questions/19301938/create-a-complete-binary-search-tree-from-list#26896494
sub _complete_level_sort {
  my $dynamic_node = shift;

  # TODO: get nodes in alphabetic order
  my ($length, $array) = _in_order($dynamic_node);
  my $index_order = _complete_order($length);

  my @nodes_in_order = ();
  for (my $i = 0; $i < $length; $i++) {
    $nodes_in_order[$i] = $array->[$index_order->[$i] -1];
  };

  return ($length, \@nodes_in_order);
};


# TODO:
#   This should be memoizable, as the
#   array is identical for a lot
#   of initial lengths, that may use a
#   lookup table!
# It may be a simple array:
# 256 => ...
# 255 => ...
# 128 => ...

memoize('_complete_order');

sub _complete_order {
  my $length = shift;
  my $offset = 0;

  my @results;
  my @queue = [$length, $offset];

  while (scalar(@queue) != 0) {
    ($length, $offset) = @{shift @queue};

    if ($length > 0) {
      # Get the middle of the first queued length
      my $middle = _complete_middle($length);
      #print "Found middle $middle for length $length at offset $offset";

      push @results, $offset + $middle;
      #print " => " . ($offset + $middle) , "\n";

      #print "-> Check for length " . ($middle - 1) . " at offset $offset\n";
      push @queue, [$middle - 1, $offset];

      #print "-> Check for length " . ($length - $middle) . " at offset " .
      #  ($offset + $middle) . "\n";
      push @queue, [$length - $middle, $offset + $middle];
    };
  }
  return \@results;
};

sub _complete_middle {
  my $n = shift;

  # TODO: Use a lookup table for common values

  # find a power of 2 <= n//2
  my $x = 1;
  while ($x <= floor($n/2)) {
    $x *= 2;
  };
  # Alternatively in Python:
  # x = 1 << (n.bit_length() - 1)

  # Case 1:
  if (floor($x/2) - 1 <= ($n - $x)) {
    return $x;
  }

  # Case 2
  return $n - floor($x/2) + 1;
};


1;


__END__








# Nils Diewald:
#   That's my trial to create a maximum compact dictionary
sub XXX_breadth_first {
  my $dynamic_node = shift;

  # Do a breadth-first search per node
  my @queue = ($dynamic_node);
  my @results = ();

  while (scalar(@queue) != 0) {

    # Get the first item
    $dynamic_node = shift @queue;

    push @queue, $dynamic_node->[LO_KID] if $dynamic_node->[LO_KID]->[0];
    push @queue, $dynamic_node->[HI_KID] if $dynamic_node->[HI_KID]->[0];
    push @results, $dynamic_node->[SPLIT_CHAR];
  };

  return \@results;
};


sub XXX_depth_first {
  my $dynamic_node = shift;

  my @stack = ($dynamic_node);
  my @results = ();

  while (scalar(@stack) != 0) {
    $dynamic_node = pop @stack;

    push @stack, $dynamic_node->[LO_KID] if $dynamic_node->[LO_KID]->[0];
    push @stack, $dynamic_node->[HI_KID] if $dynamic_node->[HI_KID]->[0];

    push @results, $dynamic_node->[SPLIT_CHAR];
  };

  return \@results;
};

