package Krawfish::Index::Store::Dynamic::Dictionary;
use strict;
use warnings;

# TODO:
#   Add parent transitions and support
#   term(leaf-node)
#
# TODO:
#   Add alias transitions, that point to a list of term ids.
#
# TODO:
#   The self-optimizing application should also
#   be used for autosuggestions.
#   This will be a separate datastructure
#   that optimizes on update (when a user searches for a term).
#   The dictionary should have a node-count and a node-limit.
#   When the node limit is exceeded on update, the datastructure
#   will remove the randomized least significant dictionary entries,
#   until the node-limit is again fine.
#   That will require the APIs:
#   ->prefix_lookup($prefix, $top_k);
#   ->update($term, $so-action)
#   ->remove_least_significant_term();

use constant {
  SPLIT_CHAR => 0,
  LO_KID => 1,
  EQ_KID => 2,
  HI_KID => 3,
  TERM_ID => 4,
  TERM_CHAR => '00',
  ALIAS_CHAR => '01'
};

# Code is based on Tree::Ternary

sub new {
  bless [], shift;
};

sub insert {
  # Iterative implementation of string insertion.
  my ($self, $term, $term_id) = @_;

  # The string ends with a terminal transition
  my (@char) = (split(//, $term), TERM_CHAR);

  my $ref = $self;
  my $retval = undef;
  my $i = 0;

  # Fetch first character
  while (my $char = $char[$i]) {

    # We use defined() to avoid
    # auto-vivification.
    if (! defined $ref->[SPLIT_CHAR]) {

      # create a new node
      $ref->[LO_KID] = [];
      $ref->[EQ_KID] = [];
      $ref->[HI_KID] = [];
      if (($ref->[SPLIT_CHAR] = $char) eq TERM_CHAR) {
        $retval = $ref->[TERM_ID] = $term_id;
      }
    }

    else {

      # here be the guts
      if ($char lt $ref->[SPLIT_CHAR]) {
        $ref = $ref->[LO_KID];
      }
      elsif ($char gt $ref->[SPLIT_CHAR]) {
        $ref = $ref->[HI_KID];
      }
      else {
        $ref = $ref->[EQ_KID];
        $i++;
      };
    };
  };

  $retval;
};


sub search {
  #
  # Iterative implementation of the string search.
  #
  # Arguments:
  #     string - string to search for in the tree
  #
  # Return value:
  #     Returns a reference to the scalar payload if the string is found,
  #     returns undef if the string is not found
  #
  my ($self, $str) = @_;
  my (@char) = (split(//, $str), TERM_CHAR);
  my $ref = $self;

  # Split character is defined
  while (defined $ref->[SPLIT_CHAR]) {

    my $char = $char[0];

    if ($char lt $ref->[SPLIT_CHAR]) {

      # Move to left
      $ref = $ref->[LO_KID];
    }

    elsif ($char gt $ref->[SPLIT_CHAR]) {

      # Move to right
      $ref = $ref->[HI_KID];
    }

    # Move to next letter
    else {
      return $ref->[TERM_ID] if $char eq TERM_CHAR;
      $ref = $ref->[EQ_KID];
      shift @char;
    };
  };
  undef;
};


# TODO:
#   Insert a term and store a term_id as an alias.
#   If the term already exist, add the term_id to the term id array.
#   This is useful for casefolded terms, that may refold to multiple
#   term_ids (therefore useful for case insensitive searching).
#   Or for accent insensitive searches.
#   Another use case are cached regular expressions, like /.+?ratu.+?/,
#   that are costly to search the dictionary for, but may easily be stored as an alias collection!
sub insert_alias {
  my ($self, $term, $term_id) = @_;
  ...
};


# This will return an array of term ids,
# in case the term is stored as an alias.
# Otherwise the array has only one item.
sub search_alias;



sub prefix_lookup {
  my ($self, $prefix, $top_k) = @_;
  ...
};

sub update {
  my ($self, $prefix, $so_strategy) = @_;
  ...
};

# Remove least significant term
sub remove_lst {
  my $self = shift;
  # On every level:
  my $node;
  if (!$node->[LO_KID] && !$node->[HI_KID]) {
    $node = $node->[EQ_KID];
  }
  elsif ($node->[LO_KID] && $node->[HI_KID]) {
    $node = int(rand(2)) ? $node->[LO_KID] : $node->[HI_KID];
  }
  elsif ($node->[LO_KID]) {
    $node = $node->[LO_KID];
  }
  else {
    $node = $node->[HI_KID];
  };

  # Delete node
  ...
};

1;
