package Krawfish::Koral::Util::Relational;
use Role::Tiny;
use Krawfish::Log;
use strict;
use warnings;

# Relational normalization role for
# Krawfish::Koral::Util::Boolean


# Central normalize call
sub normalize_relational {
  my $self = shift;
  return $self->_resolve_inclusivity;
};


# Resolve set theoretic inclusivity
sub _resolve_inclusivity {
  my $self = shift;
  my $ops = $self->operands_in_order;

  for (my $i = 1; $i < scalar(@$ops); $i++) {

    my ($op_a, $op_b) = ($ops->[$i-1], $ops->[$i]);

    # Both operands are fields
    if ($op_a->is_leaf && $op_b->is_leaf) {

      # Both operands have the same key
      if ($op_a->key eq $op_b->key &&

            # Both operands have the same field type
            $op_a->key_type eq $op_b->key_type) {

        # Both operands have the same match operator
        # TODO:
        #   Keep in mind that there may also be "gt" in the future
        #
        # Simplify geq
        if ($op_a->match eq 'geq' && $op_b->match eq 'geq') {

          # Operation is &
          # - X >= 4 & X >= 3 -> X >= 4
          if ($self->operation eq 'and') {

            # Compare
            if ($op_a->value_geq($op_b)) {
              splice @$ops, $i, 1;
              $i--;
            }
            else {
              splice @$ops, $i-1, 1;
            };
          }

          # Operation is |
          # - X >= 4 | X >= 3 -> X >= 3
          else {

            # Compare
            if ($op_a->value_geq($op_b)) {
              splice @$ops, $i-1, 1;
            }
            else {
              splice @$ops, $i, 1;
              $i--;
            };

          }
        }

        # Simplify leq
        elsif ($op_a->match eq 'leq' && $op_b->match eq 'leq') {

          # Compare

          # Operation is &
          # - X <= 4 & X <= 3    -> X <= 4
          if ($self->operation eq 'and') {
            if ($op_a->value_leq($op_b)) {
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
            if ($op_a->value_leq($op_b)) {
              splice @$ops, $i-1, 1;
            }
            else {
              splice @$ops, $i, 1;
              $i--;
            };
          }
        }

        elsif ($op_a->value_eq($op_b)) {

          # TODO:
          #   Because of operand order, there is only one variant possible
          if ($op_a->match eq 'leq' && $op_b->match eq 'geq' ||
                $op_a->match eq 'geq' && $op_b->match eq 'leq'
            ) {

            # Operation is &
            # - X >= Y & X <= Y  -> X = Y
            if ($self->operation eq 'and') {

              # Set operand match
              $op_b->match('eq');
              splice @$ops, $i-1, 1;
            }

            # Operation is |
            # - X >= Y | X <= Y  -> 1
            else {
              # Remove both operands
              splice @$ops, $i-1, 2, $self->builder->anywhere;
            }
          };
        };
      };
    };
  };

  $self->operands($ops);
  return $self;
};


1;
