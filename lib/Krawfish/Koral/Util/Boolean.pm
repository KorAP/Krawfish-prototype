package Krawfish::Koral::Util::Boolean;
use Role::Tiny;
use Krawfish::Log;
use List::MoreUtils qw!uniq!;
use strict;
use warnings;

# Base class for boolean group queries.

# Used by
# - Koral::Corpus::FieldGroup,
# - Koral::Query::TermGroup
# - Koral::Query::Or

# TODO:
#   Maybe it's easier to create multiple roles
#   ->normalize_regex
#   -> normalize_boolean
#   -> normalize_relational


use constant DEBUG => 0;

requires qw/bool_and_query
            bool_or_query
            operands_in_order/;

# TODO:
#   Introduce a ->complex attribute to all queries,
#   to guarantee that simple operands are grouped together
#   to make filtering more efficient!

# TODO:
#   To simplify this, it may be useful to use Negation instead of is_negative().
#   This means, fields with "ne" won't be "ne"-fields, but become not(term).
#   It's also easier to detect double negation.

# TODO:
#   Let normalize return a cloned query instead of in-place creation

# TODO:
#  - Deal with classes:
#    (A | !A) -> 1, aber ({1:A} | {2:!A}) -> ({1:A} | {2:!A})
#    (A & !A) -> 0, und ({1:A} & {2:!A}) -> 0

# TODO:
#   Check https://de.wikipedia.org/wiki/Boolesche_Algebra
#   for optimizations
#    or(and(a,b),and(a,c)) -> and(a,or(b,c))
#    and(or(a,b),or(a,c)) -> or(a,and(b,c))
#    not(not(a)) -> a
#    and(a,or(a,b)) -> a !! (Relevant for VCs!)
#    or(a,and(a,b)) -> a

# DeMorgan:
#    or(not(a),not(b))  -> not(and(a,b))
#    and(not(a),not(b)) -> not(or(a,b))

# TODO:
#   - Remember that corpus-groups for keywords may be weird:
#     a=1&a=2  -> a=1&a=2
#     a=1&a!=1 -> 0
#     a=1&a=1  -> a=1

# TODO:
#   Normalize regexes
#   a=/abc/ | a=/def/ 0> a=/abc|def/

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


# Normalize boolean query
sub normalize {
  my $self = shift;

  # TODO:
  # probably reiterate on all operands in that order.
  # foreach (qw/_clean_and_flatten/) { ... }

  $self = $self->_clean_and_flatten;

  unless (Role::Tiny::does_role($self, 'Krawfish::Koral::Util::Boolean')) {
    return $self->normalize;
  };

  # Recursive normalize
  my @ops = ();
  foreach my $op (@{$self->operands}) {

    # Operand is group!
    if ($op) { #  && $op->type eq $self->type) {
      push @ops, $op->normalize
    }
  };

  $self->operands(\@ops);

  # Apply normalization
  # The return value may not be a group,
  # but an andNot or a leaf after the final step
  #
  # The order is important!
  $self = $self->_clean_and_flatten;

  unless (Role::Tiny::does_role($self, 'Krawfish::Koral::Util::Boolean')) {
    return $self->normalize;
  };

  # Normalize relationally
  if (Role::Tiny::does_role($self, 'Krawfish::Koral::Util::Relational')) {
    $self = $self->normalize_relational;
  };

  return $self->_resolve_idempotence
    ->_resolve_demorgan
    ->_remove_nested_idempotence
    ->_replace_negative;
};


# Resolve idempotence
# a & a = a
# a | a = a
# TODO:
#   (a & b) | (a & b) = a & b
#   (a | b) & (a | b) = a & b
sub _resolve_idempotence {
  my $self = shift;

  print_log('kq_bool', 'Resolve idempotence for ' . $self->to_string) if DEBUG;

  # TODO:
  #   copy warning messages everywhere, when operations are changed!

  return $self if $self->is_nowhere || $self->is_anywhere;

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
      $self->move_info_from($ops->[$i]);
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
# (A | !A) -> (anywhere)
# (A & !A) -> (nowhere)
#
# TODO:
#   (A | B) & !(A | B)
sub _remove_nested_idempotence {
  my $self = shift;

  print_log('kq_bool', 'Remove nested idempotence for ' . $self->to_string) if DEBUG;

  return $self if $self->is_nowhere || $self->is_anywhere;

  my $ops = $self->operands;

  my (@plains, @neg_group, @pos_group, @pos, @neg);

  # TODO:
  #  Deal with classes
  for (my $i = 0; $i < scalar(@$ops); $i++) {

    # Operand is group
    if ($ops->[$i]->type eq $self->type &&

          # Operations are reversed
          $ops->[$i]->operation ne $self->operation) {

      if ($ops->[$i]->is_negative) {
        push @neg_group, $i;
      }

      else {
        push @pos_group, $i;
      };
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
      '  Pos-Group: ' . join(', ', @pos_group),
      '  Neg-Group: ' . join(', ', @neg_group),
      '  Plains: ' . join(', ', @plains),
      '  Neg:    ' . join(', ', @neg),
      '  Pos:    ' . join(', ', @pos),
    );
  };

  # Check for anywhere or nowhere
  # (A | !A) -> (anywhere)
  # (A & !A) -> (nowhere)
  foreach my $neg_i (@neg, @neg_group) {
    foreach my $pos_i (@pos, @pos_group) {

      if (DEBUG) {
        print_log(
          'kq_tool',
          'Compare ' . $ops->[$neg_i]->to_neutral . ' and ' .
            $ops->[$pos_i]->to_neutral
          );
      };

      # Compare terms
      if ($ops->[$neg_i]->to_neutral eq $ops->[$pos_i]->to_neutral) {

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
          $self->is_anywhere(1);
        }

        elsif ($self->operation eq 'and') {

          # Matches nowhere

          $self->is_nowhere(1);
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
    foreach my $group_i (@pos_group) {

      # Get group operands
      my $group_ops = $ops->[$group_i]->operands;

      # Get operand
      foreach (@$group_ops) {

        # Nested operand is identical
        if ($_->to_string eq $ops->[$plain_i]->to_string) {

          unless (0) { # $_->has_classes) {
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
    $self->move_info_from($ops->[$_]);
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
# Respect anywhere and nowhere
# a & b & [1] -> a & b
# a & b & [0] -> [0]
# a | b | [1] -> [1]
# a | b | [0] -> a | b
sub _clean_and_flatten {
  my $self = shift;

  return $self if $self->is_nowhere || $self->is_anywhere;

  # Get operands
  my $ops = $self->operands;

  print_log('kq_bool', 'Flatten groups of ' . $self->to_string) if DEBUG;

  # Flatten groups in reverse order
  for (my $i = scalar(@$ops) - 1; $i >= 0;) {

    # Get operand under scrutiny
    my $op = $ops->[$i];

    # Check if there is only a single operand
    # (because [1] or [] was removed)
    if (scalar(@$ops) == 1) {

      # Revert negativity on single operands
      if ($self->is_negative) {
        $op = $op->toggle_negative;
      };

      return $op;
    };

    # Remove empty elements
    if (!defined($op) || $op->is_null) {
      $self->move_info_from($ops->[$i]);

      splice @$ops, $i, 1;
    }

    # If nowhere can be matched
    elsif ($op->is_nowhere) {

      # A & B & [0] -> [0]
      if ($self->operation eq 'and') {

        print_log('kq_bool', 'Group can be simplified to [0]') if DEBUG;

        return $op;
      }

      # A | B | [0] -> A | B
      elsif ($self->operation eq 'or') {
        $self->move_info_from($ops->[$i]);
        splice @$ops, $i, 1;
      }
    }

    # If everything can be matched
    elsif ($op->is_anywhere) {

      # A & B & [1] -> A & B
      # [1] & [1] -> [1]
      if ($self->operation eq 'and') {
        $self->move_info_from($ops->[$i]);
        splice @$ops, $i, 1;
      }

      # A | B | [1] -> [1]
      elsif ($self->operation eq 'or') {

        print_log('kq_bool', 'Group can be simplified to [1]') if DEBUG;

        # Matches everywhere
        return $op;
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

  return $self if $self->is_nowhere || $self->is_anywhere;

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

      $new_group = $self->builder->bool_or(@new_group);
      # Create an andNot group in the next step
    }

    # For 'or' operation
    else {
      $new_group = $self->builder->bool_and(@new_group);
    };

    # Set group to negative
    $new_group->is_negative(1);


    # Be aware this could lead to heavy and unnecessary recursion

    my $norm = $new_group->normalize;
    $self->move_info_from($norm);
    push @$ops, $norm;
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

  print_log('kq_bool', 'Replace Negations in ' . $self->to_string) if DEBUG;

  # Check for negativity in groups to toggle all or nowhere
  if ($self->is_negative) {

    # ![1] -> [0]
    if ($self->is_anywhere) {
      $self->is_anywhere(0);
      $self->is_nowhere(1);
      $self->is_negative(0);
    }

    # ![0] -> [1]
    elsif ($self->is_nowhere) {
      $self->is_anywhere(1);
      $self->is_nowhere(0);
      $self->is_negative(0);
    };
  };

  # Return if anywhere or nowhere
  return $self if $self->is_anywhere || $self->is_nowhere;

  my $ops = $self->operands;

  # There is only a single operand
  if (@$ops == 1) {

    # Only operand is negative
    # return !a -> andNot(anywhere,a)
    if ($self->is_negative) {
      $self->is_negative(0);
      return $self->builder->bool_and_not(
        $self->builder->anywhere,
        $self
      )->normalize;
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


  # Remove the negative operand
  my $neg = pop @$ops;

  # Switch negativity
  $neg->is_negative(0);

  if (DEBUG) {
    print_log('kq_bool', 'Negative operand is removed and reversed: ' . $neg->to_string);
  };

  # Deal with operations differently
  if ($self->operation eq 'and') {

    print_log('kq_bool', 'Operation is "and"') if DEBUG;

    # There is exactly one positive operand
    if (@$ops == 1) {

      print_log('kq_bool', 'Operation on a single operand') if DEBUG;
      my $and_not = $self->builder->bool_and_not($ops->[0], $neg)->normalize;

      print_log('kq_bool', 'Created ' . $and_not->to_string) if DEBUG;
      return $and_not;
    };

    print_log('kq_bool', 'Operation on multiple operands') if DEBUG;

    # There are multiple positive operands - create a new group
    return $self->builder->bool_and_not($self, $neg)->normalize;
  }

  elsif ($self->operation eq 'or') {

    print_log('kq_bool', 'Operation is "or"') if DEBUG;

    push @$ops, $self->builder->bool_and_not(
      $self->builder->anywhere,
      $neg
    )->normalize;
    return $self;
  };

  warn 'Unknown operation';
};


# Optimize boolean queries based on their frequencies
# and there complexity
sub optimize {
  my ($self, $segment) = @_;

  # Get operands
  my $ops = $self->operands;

  # Check the frequency of all operands
  my (@freq, $query);

  # Filter out all terms that do not occur
  for (my $i = 0; $i < @$ops; $i++) {

    # Get query operation for next operand
    my $next = $ops->[$i]->optimize($segment);

    # Get maximum frequency
    my $freq = $next->max_freq;

    # Push to frequency list
    push @freq, [$next, $freq];
  };

  # Sort operands based on ascending frequency
  # This is - however - rather irrelevant for or-queries,
  # but it may help caching by introducing deterministic ordering
  @freq = sort {
    ($a->[1] < $b->[1]) ? -1 :
      (($a->[1] > $b->[1]) ? 1 :
       ($a->[0]->to_string cmp $b->[0]->to_string))
    } @freq;

  # Operation is 'or'
  if ($self->operation eq 'or') {
    print_log('kq_bool', 'Prepare or-group') if DEBUG;

    # Move simple queries to the front, so when filtering, leaf groups
    # will be filtered in groups
    @freq = sort {
      $a->[0]->complex == $b->[0]->complex ? 0 :
        (
          $a->[0]->complex && !$b->[0]->complex ? 1 : -1
        )
    } @freq;

    # Ignore non-existing terms
    while (@freq && $freq[0]->[1] == 0) {
      shift @freq;
    };

    # No valid operands exist
    if (@freq == 0) {
      return Krawfish::Query::Nowhere->new;
    };

    # Get the first operand
    $query = shift(@freq)->[0];

    # For all further queries, create a query tree
    while (@freq) {
      my $next = shift(@freq)->[0];

      # TODO: Distinguish here between classes and non-classes!
      $query = $self->bool_or_query(
        $query,
        $next
      );
    };
  }

  # Operation is 'and'
  elsif ($self->operation eq 'and') {

    print_log('kq_bool', 'Prepare and-group') if DEBUG;


    # If the least frequent operand does not exist,
    # the whole group can't exist
    if ($freq[0]->[1] == 0) {

      # One operand is not existing
      return Krawfish::Query::Nowhere->new;
    };

    # Get the first operand
    $query = shift(@freq)->[0];

    # Make the least frequent terms come first in constraint
    while (@freq) {
      my $next = shift(@freq)->[0];

      # Create constraint with the least frequent as second (buffered) operand
      $query = $self->bool_and_query($next, $query);
    };
  }

  # Operation is unknown!
  else {
    warn 'Should never happen!';
  };

  # Return nowhere if nowhere matches!
  if ($query->max_freq == 0) {
    return Krawfish::Query::Nowhere->new;
  };

  return $query;
};


# Toggle the operation
sub toggle_operation {
  my $self = shift;
  if ($self->operation eq 'or') {
    $self->operation('and');
  }
  elsif ($self->operation eq 'and') {
    $self->operation('or');
  };
};


# Create operands in order
sub operands_in_order {
  my $self = shift;
  my $ops = $self->{operands};
  return [ sort { ($a && $b) ? ($a->to_sort_string cmp $b->to_sort_string) : 1 } @$ops ];
};


1;


__END__
