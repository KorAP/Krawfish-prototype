package Krawfish::Koral::Util::BooleanTree;
use Krawfish::Log;
use List::MoreUtils qw!uniq!;
use strict;
use warnings;

# This can be used by Koral::FieldGroup and Koral::TermGroup

use constant DEBUG => 1;

# TODO:
#   Change andNot([1],X) to not(x),
#   so this can be used for tokenGroups without a change

# TODO:
#   To simplify this, it may be useful to use Negation instead of is_negative().
#   This means, fields with "ne" won't be "ne"-fields, but become not(term).
#   It's also easier to detect double negation.

# TODO:
#  - Deal with classes:
#    (A | !A) -> 1, aber ({1:A} | {2:!A}) -> ({1:A} | {2:!A})
#    (A & !A) -> 0, und ({1:A} & {2:!A}) -> 0

# Check https://de.wikipedia.org/wiki/Boolesche_Algebra
# for optimizations
# TODO:
#    or(and(a,b),and(a,c)) -> and(a,or(b,c))
#    and(or(a,b),or(a,c)) -> or(a,and(b,c))
#    not(not(a)) -> a
#    and(a,or(a,b)) -> a !! (Relevant for VCs!)
#    or(a,and(a,b)) -> a

# DeMorgan:
#    or(not(a),not(b))  -> not(and(a,b))
#    and(not(a),not(b)) -> not(or(a,b))

# TODO:
#   from managing gigabytes bool_optimiser.c
#/* =========================================================================
# * Function: OptimiseBoolTree
# * Description: 
# *      For case 2:
# *        Do three major steps:
# *        (i) put into standard form
# *            -> put into DNF (disjunctive normal form - or of ands)
# *            Use DeMorgan's, Double-negative, Distributive rules
# *        (ii) simplify
# *             apply idempotency rules
# *        (iii) ameliorate
# *              convert &! to diff nodes, order terms by frequency,...
# *     Could also do the matching idempotency laws i.e. ...
# *     (A | A), (A | !A), (A & !A), (A & A), (A & (A | B)), (A | (A & B)) 
# *     Job for future.... ;-) 
# * Input: 
# * Output: 
# * ========================================================================= */
#/* =========================================================================
# * Function: DoubleNeg
# * Description: 
# *      !(!(a) = a
# *      Assumes binary tree.
# * Input: 
# * Output: 
# * ========================================================================= */
#/* =========================================================================
# * Function: AndDeMorgan
# * Description: 
# *      DeMorgan's rule for 'not' of an 'and'  i.e. !(a & b) <=> (!a) | (!b)
# *      Assumes Binary Tree
# * Input: 
# *      not of and tree
# * Output: 
# *      or of not trees
# * ========================================================================= */
#/* =========================================================================
# * Function: OrDeMorgan
# * Description: 
# *      DeMorgan's rule for 'not' of an 'or' i.e. !(a | b) <=> (!a) & (!b)
# *      Assumes Binary Tree
# * Input: 
# *      not of and tree
# * Output: 
# *      or of not trees
# * ========================================================================= */
#/* =========================================================================
# * Function: PermeateNots
# * Description: 
# *      Use DeMorgan's and Double-negative
# *      Assumes tree in binary form (i.e. No ands/ors collapsed)
# * Input: 
# * Output: 
# * ========================================================================= */
#/* =========================================================================
# * Function: AndDistribute
# * Description: 
# *      (a | b) & A <=> (a & A) | (b & A)
# * Input: 
# *      binary tree of "AND" , "OR"s.
# * Output: 
# *      return 1 if changed the tree
# *      return 0 if there was NO change (no distributive rule to apply)
# * ========================================================================= */
#/* =========================================================================
#/* =========================================================================
# * Function: AndSort
# * Description: 
# *      Sort the list of nodes by increasing doc_count 
# *      Using some Neil Sharman code - pretty straight forward.
# *      Note: not-terms are sent to the end of the list
# * Input: 
# * Output: 
# * ========================================================================= */

# From managing gigabytes bool_optimiser.c
# - function: TF_Idempotent -> DONE


# TODO:
#   This should return a cloned query instead of in-place creation
sub normalize {
  my $self = shift;

  # Recursive normalize
  foreach my $op (@{$self->operands}) {

    # Operand is group!
    if ($op && $op->type eq $self->type) {
      $op->normalize
    };
  };

  # Apply normalization
  # The return value may not be a group,
  # but an andNot or a leaf after the final step
  $self->_clean_and_flatten
    ->_resolve_idempotence
    ->_remove_nested_idempotence
    ->_resolve_demorgan
    ->_replace_negative;
};


# Resolve idempotence
# a & a = a
# a | a = a
sub _resolve_idempotence {
  my $self = shift;

  print_log('kq_bool', 'Resolve idempotence for ' . $self->to_string) if DEBUG;

  return $self if $self->is_nothing || $self->is_any;

  # Get operands in order to identify identical subcorpora
  my $ops = $self->operands_in_order;

  my ($i, @ops) = (0);

  # Get length
  my $length = scalar @$ops;

  # Create new operand list
  @ops = ($ops->[$i++]);

  # Iterate over all operands
  while ($i < $length) {

    # (A | A)
    # (A & A)
    if ($ops->[$i-1]->to_string ne $ops->[$i]->to_string) {
      push @ops, $ops->[$i]
    }

    elsif (DEBUG) {
      print_log('kq_bool', 'Subcorpora are idempotent');
    };

    $i++;
  };

  # Set operands
  $self->operands(\@ops);

  $self;
};


# Remove matching idempotence
# (A & (A | B)) -> A
# (A | (A & B)) -> A
# (A | !A) -> (any)
# (A & !A) -> (nothing)
#
# TODO:
#   (A | B) & !(A | B)
sub _remove_nested_idempotence {
  my $self = shift;

  print_log('kq_bool', 'Remove nested idempotence for ' . $self->to_string) if DEBUG;

  return $self if $self->is_nothing || $self->is_any;

  my $ops = $self->operands;

  my (@plains, @groups, @pos, @neg);

  # TODO:
  #  Deal with classes
  for (my $i = 0; $i < scalar(@$ops); $i++) {

    # Operand is group
    if ($ops->[$i]->type eq $self->type &&

          # Operations are reversed
          $ops->[$i]->operation ne $self->operation) {

      push @groups, $i;
    }

    # Operand is leaf
    elsif ($ops->[$i]->is_leaf) {
      push @plains, $i;

      # Item is negative
      if ($ops->[$i]->is_negative) {
        push @neg, $i;
      }

      # Item is positive
      else {
        push @pos, $i;
      }
    };
  };

  if (DEBUG) {
    print_log(
      'kq_bool',
      'Index lists created for ' . $self->to_string . ':',
      '  Groups: ' . join(', ', @groups),
      '  Plains: ' . join(', ', @plains),
      '  Neg:    ' . join(', ', @neg),
      '  Pos:    ' . join(', ', @pos),
    );
  };

  # Check for any or nothing
  # (A | !A) -> (any)
  # (A & !A) -> (nothing)
  foreach my $neg_i (@neg) {
    foreach my $pos_i (@pos) {

      # Compare terms
      if ($ops->[$neg_i]->to_term eq $ops->[$pos_i]->to_term) {

        if (DEBUG) {
          print_log(
            'kq_bool',
            'Found idempotent group for ' .
              $self->operation .
              '(' . $ops->[$neg_i]->to_string . ',' . $ops->[$pos_i]->to_string . ')'
            );
        };

        if ($self->operation eq 'or') {

          # Matches everything
          $self->is_any(1);
        }
        elsif ($self->operation eq 'and') {

          # Matches nothing
          $self->is_nothing(1);
        };

        # Remove all operands
        $self->operands([]);

        # Stop further processing
        return $self;
      };
    };
  };

  my @remove_groups = ();

  # Iterate over all groups and plains
  # (A & (A | B)) -> A
  # (A | (A & B)) -> A
  foreach my $plain_i (@plains) {
    foreach my $group_i (@groups) {

      # Get group operands
      my $group_ops = $ops->[$group_i]->operands;

      # Get operand
      foreach (@$group_ops) {

        # Nested operand is identical
        if ($_->to_string eq $ops->[$plain_i]->to_string) {

          unless ($_->has_classes) {
            if (DEBUG) {
              print_log('kq_bool', 'Remove nested idempotence in ' . $self->to_string);
            };

            push @remove_groups, $group_i;
          }
          else {
            warn 'Behaviour for classes is undefined!';
          };
        };
      };
    };
  };


  # Get a list of all removable items in reverse order
  # To remove irrelevant nested groups
  foreach (uniq reverse sort @remove_groups) {
    splice @$ops, $_, 1;
  };

  return $self;
};


# Remove empty
# a & () = a
# a | () = a
#
# Flatten groups
# ((a & b) & c) -> (a & b & c)
# ((a | b) | c) -> (a | b | c)
#
# Respect any and nothing
# a & b & [1] -> a & b
# a & b & [0] -> [0]
# a | b | [1] -> [1]
# a | b | [0] -> a | b
sub _clean_and_flatten {
  my $self = shift;

  return $self if $self->is_nothing || $self->is_any;

  # Get operands
  my $ops = $self->operands;

  print_log('kq_bool', 'Flatten groups') if DEBUG;

  # Flatten groups in reverse order
  for (my $i = scalar(@$ops) - 1; $i >= 0;) {

    # Get operand under scrutiny
    my $op = $ops->[$i];

    # Remove empty elements
    if (!defined($op) || $op->is_null) {
      splice @$ops, $i, 1;
    }

    # If nothing can be matched
    elsif ($op->is_nothing) {

      # A & B & [0] -> [0]
      if ($self->operation eq 'and') {

        print_log('kq_bool', 'Group can be simplified to [0]') if DEBUG;

        # Matches nowhere!
        @$ops = ();
        $self->is_nothing(1);
        last;
      }

      # A | B | [0] -> A | B
      elsif ($self->operation eq 'or') {
        splice @$ops, $i, 1;
      }
    }

    # If everything can be matched
    elsif ($op->is_any) {

      # A & B & [1] -> A & B
      if ($self->operation eq 'and') {
        splice @$ops, $i, 1;
      }

      # A | B | [1] -> [1]
      elsif ($self->operation eq 'or') {

        print_log('kq_bool', 'Group can be simplified to [1]') if DEBUG;

        # Matches everywhere
        @$ops = ();
        $self->is_any(1);
        last;
      }
    }

    # Is a nested group
    elsif ($op->type eq $self->type) {

      # Get nested operands
      # TODO:
      #   Rename to $ops
      my $operands = $op->operands;
      my $nr = @$operands;

      # Simple ungroup
      if (!$op->is_negative && $op->operation eq $self->operation) {

        print_log('kq_bool', 'Group can be embedded') if DEBUG;

        splice @$ops, $i, 1, @$operands;
        $i+= $nr;
      }

      # Resolve grouped deMorgan-negativity
      elsif ($op->is_negative && $op->operation ne $self->operation) {

        print_log('kq_bool', 'Group can be resolved with demorgan') if DEBUG;

        splice @$ops, $i, 1, map { $_->toggle_negative; $_ } @$operands;
        $i+= $nr;
      };
    };

    $i--;
  };

  $self->operands($ops);

  print_log('kq_bool', 'Group is now ' . $self->to_string) if DEBUG;

  $self;
};


# Resolve DeMorgan
# !a & !b = !(a | b)
# !a | !b = !(a & b)
# Afterwards the group will only contain a single negative element at the end
sub _resolve_demorgan {
  my $self = shift;

  print_log('kq_bool', 'Resolve DeMorgan in ' . $self->to_string) if DEBUG;

  return $self if $self->is_nothing || $self->is_any;

  # Split negative and operands
  my (@neg, @pos) = ();
  my $ops = $self->operands;

  # Iterate over operands
  for (my $i = 0; $i < @$ops; $i++) {

    # Check if negative
    if ($ops->[$i]->is_negative) {
      push @neg, $i;
    }
    else {
      push @pos, $i;
    };
  };

  # Found no negative operands
  return $self unless @neg;

  if (DEBUG) {
    print_log(
      'kq_bool',
      'Index lists created for ' . $self->to_string . ':',
      '  Neg:    ' . join(', ', @neg),
      '  Pos:    ' . join(', ', @pos),
    );
  };

  # Everything is negative
  unless (@pos) {

    print_log('kq_bool', 'The whole group is negative') if DEBUG;

    foreach (@neg) {
      $ops->[$_]->toggle_negative;
    };
    $self->toggle_operation;
    $self->toggle_negative;
    return $self;
  };

  # There are no negative operands
  return $self unless @neg;

  # There are negative operands

  # Group all negative operands
  # and apply demorgan
  my @new_group = ();

  # Get all negative items and create a new group
  foreach (uniq reverse sort @neg) {

    if (DEBUG) {
      print_log('kq_bool', 'Add operand to group: ' . $ops->[$_]->to_string);
    };

    # Remove from old group
    my $neg_op = splice(@$ops, $_, 1);

    # Reset negativity
    $neg_op->is_negative(0);

    # Put in new group
    push(@new_group, $neg_op);
  };

  # Only a single negative operand
  if (scalar(@new_group) == 1) {

    print_log('kq_bool', 'Single negative operand') if DEBUG;

    # Reintroduce negativity
    $new_group[0]->is_negative(1);

    # Add negative operand at the end
    push @$ops, $new_group[0];
  }

  # Create a group with negative operands
  else {

    print_log('kq_bool', 'Create group with negation') if DEBUG;

    my $new_group;

    # Get reverted DeMorgan group
    if ($self->operation eq 'and') {

      $new_group = $self->build_or(@new_group);
      # Create an andNot group in the next step
    }

    # For 'or' operation
    else {
      $new_group = $self->build_and(@new_group);
    };

    # Set group to negative
    $new_group->is_negative(1);

    push @$ops, $new_group;
  };

  # $self->operands($ops);

  print_log('kq_bool', 'Group is now ' . $self->to_string) if DEBUG;

  return $self;
};


# To make queries with negation more efficient,
# replace (a & !b) with andNot(a,b)
# and (a | !b) with (a | andNot([1],b))
sub _replace_negative {
  my $self = shift;

  print_log('kq_bool', 'Replace negations in ' . $self->to_string) if DEBUG;

  # Check for negativity in groups to toggle all or nothing
  if ($self->is_negative) {

    # ![1] -> [0]
    if ($self->is_any) {
      $self->is_any(0);
      $self->is_nothing(1);
      $self->is_negative(0);
    }

    # ![0] -> [1]
    elsif ($self->is_nothing) {
      $self->is_any(1);
      $self->is_nothing(0);
      $self->is_negative(0);
    };
  };

  # Return if any or nothing
  return $self if $self->is_any || $self->is_nothing;

  my $ops = $self->operands;

  # There is only a single operand
  if (@$ops == 1) {

    # Only operand is negative
    # return !a -> andNot(any,a)
    if ($self->is_negative) {
      $self->is_negative(0);
      return $self->build_and_not(
        $self->build_any,
        $self
      );
    };

    # Only operand does not need a group
    return $ops->[0];
  };

  print_log('kq_bool', 'Check final operand on negativity') if DEBUG;

  # There is only one single negative operand possible!
  # And it's at the end!

  # All operands are positive
  return $self unless $ops->[-1]->is_negative;

  # Group all positive operands
  print_log('kq_bool', 'Create group with negation') if DEBUG;

  #if ($self->is_negative) {
  #  warn 'Behaviour on negativity is currently not supported here';
  #};

  # Remove the negative operand
  my $neg = pop @$ops;

  # Switch negativity
  $neg->is_negative(0);

  print_log('kq_bool', 'Remove negative operand is reversed: ' . $neg->to_string) if DEBUG;

  if ($self->operation eq 'and') {

    # There is exactly one positive operand
    if (@$ops == 1) {
      return $self->build_and_not($ops->[0], $neg);
    };

    # There are multiple positive operands - create a new group
    return $self->build_and_not($self, $neg);
  }

  elsif ($self->operation eq 'or') {

    push @$ops, $self->build_and_not(
      $self->build_any,
      $neg
    );
    return $self;
  };

  warn 'Unknown field operation';
};

1;

__END__

  # First pass - flatten and cleanup
  for (my $i = @$ops - 1; $i >= 0;) {

    # Clean null
    if ($ops->[$i]->is_null) {
      splice @$ops, $i, 1;
    }

    # Flatten groups
    elsif ($ops->[$i]->type eq 'termGroup' &&
             $ops->[$i]->operation eq $self->operation) {
      my $operands = $ops->[$i]->operands;
      my $nr = @$operands;
      splice @$ops, $i, 1, @$operands;
      $i+= $nr;
    }

    # Element is negative - remember
    elsif ($ops->[$i]->is_negative) {
      push @negatives, splice @$ops, $i, 1
    };

    $i--
  };


  # No positive operator valid
  if (@$ops == 0) {
    $self->error(000, 'Negative queries are not supported');
    return;
  }



1;
