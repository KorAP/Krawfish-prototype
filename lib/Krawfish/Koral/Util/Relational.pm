package Krawfish::Koral::Util::Relational;
use Role::Tiny;
use Krawfish::Log;
use strict;
use warnings;

# Relational normalization role for
# Krawfish::Koral::Util::Boolean

use constant DEBUG => 0;

# TODO:
#   Combine AND-constraints on the same relational key
#   to range queries, e.g.
#     date > 2014-03-01 & date <= 2017-02
#     to
#     date in [2014-03-01[--2017-02]]
#
#     length >= 5 & length < 2
#     to
#     length in [[5--]2]
#
#     The inner brackets mark inclusivity or exclusivity

# Resolve set theoretic inclusivity and exclusivity
sub _resolve_inclusivity_and_exclusivity {
  my $self = shift;

  print_log('kq_relational', ': Resolve inclusivity and exclusivity for ' . $self->to_string) if DEBUG;

  return if $self->is_nowhere || $self->is_anywhere;

  # Keep track of changes
  my $changes = 0;

  my $ops = $self->operands_in_order;

  for (my $i = 1; $i < scalar(@$ops); $i++) {

    my ($op_a, $op_b) = ($ops->[$i-1], $ops->[$i]);

    # Both operands are fields
    next unless $op_a->is_leaf && $op_b->is_leaf;

    # Both operands require the same key
    next unless $op_a->key eq $op_b->key;

    # Both operands require the same field type
    next unless $op_a->key_type eq $op_b->key_type;

    # At least one operand needs to be relational
    next unless $op_a->is_relational || $op_b->is_relational;

    if (DEBUG) {
      print_log(
        'kq_relational',
        'Compare ' . $op_a->to_string . ' and ' . $op_b->to_string
      );
    };

    # Both operands have the same match operator
    # Simplify geq (> or >=)
    if ($op_a->match eq 'gt' && $op_b->match eq 'gt') {

      if (DEBUG) {
        print_log('kq_relational', 'Both operands are gt (inclusive or not)');
      };

      # Operation is &
      # - X >(=) 4 & X >(=) 3 -> X >(=) 4
      if ($self->operation eq 'and') {

        # Compare
        if ($op_a->value_gt($op_b)) {

          # $op_a is greater
          # X >= 4 & X >= 3 -> X >= 4
          # X > 4 & X >= 3 -> X > 4
          splice @$ops, $i, 1;
          $i--;
        }
        else {
          splice @$ops, $i-1, 1;
        };
      }

      # Operation is |
      # - X >= 4 | X >= 3 -> X >= 3
      # - X > 4 | X > 3 -> X > 3
      else {

        # Compare
        if ($op_a->value_gt($op_b)) {
          splice @$ops, $i-1, 1;
        }
        else {
          splice @$ops, $i, 1;
          $i--;
        };
      };
      $changes++;
    }

    # Simplify leq (< or <=)
    elsif ($op_a->match eq 'lt' && $op_b->match eq 'lt') {

      if (DEBUG) {
        print_log('kq_relational', 'Both operands are leq');
      };

      # Compare

      # Operation is &
      # - X <= 4 & X <= 3    -> X <= 4
      if ($self->operation eq 'and') {
        if ($op_a->value_lt($op_b)) {
          splice @$ops, $i, 1;
          $i--;
        }
        else {
          splice @$ops, $i-1, 1;
        };
      }

      # Operation is |
      # - X <= 4 | X <= 3    -> X <= 3
      else {
        if ($op_a->value_lt($op_b)) {
          splice @$ops, $i-1, 1;
        }
        else {
          splice @$ops, $i, 1;
          $i--;
        };
      };
      $changes++;
    }

    # The value is identical
    elsif ($op_a->value_eq($op_b)) {

      # TODO:
      #   Because of operand order, there is only one variant possible
      if (
        ($op_a->is_inclusive && $op_b->is_inclusive) && (
          (($op_a->match eq 'lt' && $op_b->match eq 'gt') ||
             ($op_a->match eq 'gt' && $op_b->match eq 'lt')
           )
        )) {

        # Operation is &
        # - X >= Y & X <= Y  -> X = Y
        if ($self->operation eq 'and') {

          # Set operand match
          $op_b->match('eq');
          splice @$ops, $i-1, 1;
        }

        # Operation is |
        # - X >= Y | X <= Y  -> [1]
        else {
          # Remove both operands
          splice @$ops, $i-1, 2, $self->builder->anywhere;
        };

        $changes++;
      }

      # The value is identical and one operand is an eq while the other one is inclusive
      # TODO: Depending on the order only one variant possible
      elsif (
        ($op_a->match eq 'eq' && $op_b->is_inclusive) ||
          ($op_b->match eq 'eq' && $op_a->is_inclusive)
        ) {

        # - X >= Y & X = Y -> X = Y
        if ($self->operation eq 'and') {

          # Set operand match
          $op_b->match('eq');
          splice @$ops, $i-1, 1;
        }

        # Though this doesn't help much
        # - X >= Y | X = Y -> X >= Y
        # - X <= Y | X = Y -> X <= Y
        else {

          # First operand is equal
          if ($op_a->match eq 'eq') {
            splice @$ops, $i-1, 1;
          }

          # Second operand is equal
          else {
            splice @$ops, $i, 1;
            $i--;
          };
        };
        $changes++;
      }

      elsif (
        ($op_a->match eq 'ne' && $op_b->is_inclusive) ||
          ($op_b->match eq 'ne' && $op_a->is_inclusive)
        ) {

        # - X >= Y & X != Y -> X > Y
        if ($self->operation eq 'and') {

          # TODO:
          #   This optimization is only possible with
          #   support for > and <

          # # First remove unequal operand
          # if ($op_a->match eq 'ne') {
          #   splice @$ops, $i-1, 1;
          # }
          # else {
          #   splice @$ops, $i, 1;
          #   $i--;
          # }
          #
          # my $op = $ops->[$i];
          # if ($op->match eq 'leq') {
          #   $op->match('le');
          # };
        }

        # - X >= Y | X != Y -> [1]
        # - X <= Y | X != Y -> [1]
        else {
          # Remove both operands
          splice @$ops, $i-1, 2, $self->builder->anywhere;
          $changes++;
        };
        # }
        #
        # TODO:
        #   Deal with < and > without inclusivity!
        #
        # else {
      };
    };
  };

  return unless $changes;

  $self->operands($ops);
  return $self;
};


1;
