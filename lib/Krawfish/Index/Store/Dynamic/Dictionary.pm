package Krawfish::Index::Store::Dynamic::Dictionary;
use strict;
use warnings;

use constant {
  SPLIT_CHAR => 0,
  LO_KID => 1,
  EQ_KID => 2,
  HI_KID => 3,
  TERM_ID => 4,
  TERM_CHAR => '00'
};

# Code is based on Tree::Ternary

sub new {
  bless [], shift;
};

sub insert {
  # Iterative implementation of string insertion.
  my ($self, $str, $term_id) = @_;

  # The string ends with a terminal transition
  my (@char) = (split(//, $str), TERM_CHAR);

  my $ref = $self;
  my $retval = undef;

  while (@char) {

    my $char = $char[0];

    if (! defined $ref->[SPLIT_CHAR]) { # We use defined() to avoid
      # auto-vivification.

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
        shift @char;
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


sub search_i;

1;
