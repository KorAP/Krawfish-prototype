package Krawfish::Index::Store::V1::Dictionary;
use Krawfish::Log;
use strict;
use warnings;

# This is a naive implementation!

# This is a compact array based trie representation.
# On each letter node, binary search and linear search can be done over
# an alphabetically sorted list.
# The pointers are doubled to make reverse retrieval
# on term_ids simple.
# The dictionary can be loaded with minimal footprint using mmap
#
# IDEAS:
#   To improve footprint:
#   nodes with more than 128 childs may need a structure like
#   [char:int32]

# The term_id array points to the '00' terminal nodes of the tree structure.

# TODO:
#   It may be useful to check for big file limitations
#   https://www.codeproject.com/articles/563200/indexer-index-large-collections-by-different-keys

# TODO:
#   In Lucy the dictionary is stored in a list
#   using incremental encoding / front coding.
#   In Atire (http://atire.org/index.php?title=Index_Structure) the
#   dictionary is split into a top part (first 4 characters) and a
#   second part.

# TODO:
#   Ranks for terms should be added at a prefinal level for surface
#   terms with an epsilon character to ignore
#   Example (d=down;u=up)
#
#   *[d][u]...->d[d][u]...->e[d][u]...->r[d][u]...
#   ->0[d][u][forward-rank][backward-rank]->[terminal][u][term-id]
#
#   That way a lookup for a rank based on term id is very fast
#   and not very costly (as the term id array access is O(1))!

# TODO:
#   The information if a field is sortable, should also be added
#   to a preterminal epsilon edge to all field-ids

# TODO:
#   Use linear search for small arrays, see
#   https://schani.wordpress.com/2010/04/30/linear-vs-binary-search/
#   Because most arrays are small, prefer linear search over binary search

# TODO: Support collations
#   - https://msdn.microsoft.com/en-us/library/ms143726.aspx
#   - http://userguide.icu-project.org/collation

# This is necessary to deal with the dynamic structure
use constant {
  SPLIT_CHAR => 0,
  LO_KID     => 1,
  EQ_KID     => 2,
  HI_KID     => 3,
  TERM_ID    => 4,
  TERM_CHAR  => '00',
  TREE       => 0,
  TERM_IDS   => 1,
  DEBUG      => 0
};


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
  my ($class, $tst) = @_;
  bless [convert_to_array($tst)], $class;
};


# Get tree object
sub tree {
  $_[0]->[TREE];
};


# Get term id list
sub term_ids {
  $_[0]->[TERM_IDS];
};


# Search for a term and return a term id
# Alternatively returns iterator
sub search {
  my ($self, $term) = @_;

  my @term = (split('', $term), TERM_CHAR);
  my $consumed = 0;

  if (DEBUG) {
    print_log('dict_v1', 'Search for term ' . $term);
  };

  my $tree = $self->tree;

  my $term_id = 0;
  my $offset = 0;

  # Get node length
  my $length = $tree->[$offset];

  # Start at first character (after up-field)
  $offset += 2;
  my $start = $offset;
  while (1) {

    if (DEBUG) {
      print_log('dict_v1', 'Compare ' . $tree->[$offset] . ' and ' . $term[$consumed]);
    };

    # No valid node in existence
    if ($tree->[$offset] gt $term[$consumed]) {
      return;
    }

    # Node array exceeded
    elsif ($offset >= $start + ($length * 2)) {
      return;
    }

    # Characters match - consume!
    elsif ($tree->[$offset] eq $term[$consumed]) {

      if (DEBUG) {
        print_log('dict_v1', 'Character ' . $tree->[$offset] . ' is fine - go on');
      };

      if ($term[$consumed] eq TERM_CHAR) {
        if (DEBUG) {
          print_log('dict_v1', 'Character is final - stop');
        };
        return $tree->[$offset+1];
      };

      $consumed++;

      # Point to the down field
      $offset = $tree->[$offset + 1];
      $length = $tree->[$offset];
      $start = $offset + 2;

      if (DEBUG) {
        print_log('dict_v1', "Move to next node at $offset with length $length");
      };
    };

    $offset +=2;
  };
  return;
};


# Search with ignoring case
# Returns iterator
sub search_case_insensitive {
  ...
};


# Search with ignoring diacritics
# Returns iterator
sub search_diacritic_insensitive {
  ...
};


# Search with k errors
# Returns iterator
sub search_approximative {
  ...
};


# Search using regular expression
# Returns iterator
sub search_regex {
  ...
};


# Merge static tree with dynamic tree
sub merge {
  ...
};


# Return iterator of term ids
# TODO:
#   Be aware, this is only in collation
#   order of the insertion, that may not be very helpful.
# sub in_prefix_order {
#   ...
# };


# May not be helpful
# sub in_suffix_order {
#   ...
# };




# Read with header
# This may first be done in the parent dictionary module
# and then be delegated to the right version
sub from_file {
  ...
};


# Write a header
sub to_file {
  ...
};


# Stringification
sub to_string {
  my ($self, $marker) = @_;
  my $marked_tree = '';
  my $tree = $self->tree;
  foreach (my $i = 0; $i < @$tree; $i++) {
    $marked_tree .= ' <' if $marker && $i == $marker;
    $marked_tree .= $tree->[$i] ? '[' . $tree->[$i] . ']' : '[]';
    $marked_tree .= '> ' if $marker && $i == $marker;
  };
  my $ids  = join '', map { $_ ? "[$_]" : '[]' } @{$self->term_ids};
  return "tree=$marked_tree;ids=$ids";
};


# Convert tree representation to array representation
# P.S. I tried to use only one field for double linking,
#      but this didn't work so well
sub convert_to_array {
  my $node = shift;

  # Absolute offset of tree (identical to scalar(@tree))
  my $offset = -1;
  my $parent_offset;
  my $top;

  my (@tree, @term_ids) = ();

  my ($length, $list);

  # Initialize stack
  my @stack = [$node, 0, 0];

  # As long as there are elements on the stack, go on.
  while (@stack) {

    # Get the leftest child
    ($node, $parent_offset) = @{shift @stack};

    # Get the leftest children
    ($length, $list) = _in_order($node);

    # There are no more childs
    next if $length == 0;

    # Add one node level to tree
    push @tree, $length;
    $offset++;
    $top = $offset;

    # Add the reference to the top node (only once)
    push @tree, '^' . $parent_offset;
    $offset++;

    my @node = ();
    foreach (@$list) {

      # Add character to tree
      push @tree, $_->[SPLIT_CHAR];
      $offset++;

      if (DEBUG) {
        print_log('dict_v1', 'Set ' . $_->[SPLIT_CHAR] . ' at offset ' . ($offset + 1));
      };

      # Add empty child link
      push @tree, '?';
      $offset++;

      # For lower nodes, add information to parent nodes
      if ($parent_offset > 0) {
        if (DEBUG) {
          print_log('dict_v1', "Set parent offset $parent_offset to = $offset");
        };

        # Set the parent offset to the top
        $tree[$parent_offset] = $top;
      };

      # Node is terminal
      if ($_->[SPLIT_CHAR] eq TERM_CHAR) {

        # Point term id to the "up" field
        $term_ids[$_->[TERM_ID]] = $top + 1;

        if (DEBUG) {
          print_log(
            'dict_v1',
            "Set final offset $offset to term ID " . $_->[TERM_ID]
          );
        };

        # Set terminal id to node
        $tree[$offset] = $_->[TERM_ID];
      };

      # Add in alphabetical order
      # Currently offset contains the ?-Position of $_
      push @node, [$_->[EQ_KID], $offset, $parent_offset, $top];
    };

    # add to left
    unshift @stack, @node;
  };

  return (\@tree, \@term_ids);
};


# Get term from term id
# Move to top, character by character
sub term_by_term_id {
  my ($self, $term_id) = @_;

  my $tree = $self->tree;

  my @term = ();

  if (DEBUG) {
    print_log('dict_v1', 'Get term by term id ' . $term_id);
  };

  # Get offset from term ids
  my $offset = $self->term_ids->[$term_id];

  return unless $offset;

  if (DEBUG) {
    print_log('dict_v1', 'Tree has start at ' . $offset . ': ' . $self->to_string($offset));
  };

  # Get offset from tree
  $offset = substr($tree->[$offset], 1);


  my $i = 0;
  my $debug = '';

  # Move to root
  while ($offset != 0) {
    my $char = $tree->[--$offset];
    unshift @term, $char;

    if (DEBUG) {
      print_log('dict_v1', "Found $char at $offset in " . $self->to_string($offset));
    };

    # Just for security
    last if $i++ > 20;

    # Iterate to the beginning of the node to get the top offset
    # TODO:
    #   Alternatively the local offset could be stored in the first byte
    #   as long as only 256 characters are in the node
    #   if there are more, mark the node 0 and iterate
    $offset--;
    while (index($tree->[$offset], '^') != 0) {

      $offset -=2;
    };

    print_log('dict_v1', "Found ^up at $offset") if DEBUG;

    # Get up-direction and move
    $offset = $self->tree->[$offset];
    $offset = substr($offset, 1);
  };

  join '', @term;
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


1;


__END__
