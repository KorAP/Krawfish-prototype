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
  return $self->_resolve_supersets;
};


# - X > 4 & X > 3    -> X > 4
# - X < 4 & X < 3    -> X < 4
# - X > 4 | X > 3    -> X > 3
# - X < 4 | X < 3    -> X < 3
sub _resolve_supersets {
  my $self = shift;
  my $ops = $self->operands_in_order;

  if ($self->operation eq 'and') {

    for (my $i = 1; $i < scalar(@$ops); $i++) {

      # Both operands are fields
      if ($ops->[$i]->type eq 'field' && $ops->[$i-1]->type eq 'field') {

        # Both operands have the same key
        if ($ops->[$i]->key eq $ops->[$i-1]->key &&

              # Both operands have the same field type
              $ops->[$i]->key_type eq $ops->[$i-1]->key_type) {

          # Both operands have the same match operator
          # TODO:
          #   Keep in mind that there may also be "gt" in the future
          if ($ops->[$i]->match eq 'geq' && $ops->[$i-1]->match eq 'geq') {

            # Compare
            if ($ops->[$i]->value_geq($ops->[$i-1])) {
              splice @$ops, $i-1, 1;
            }
            else {
              splice @$ops, $i, 1;
              $i--;
            };
          };
        };
      };
    };

    $self->operands($ops);
  };

  return $self;
};



# - X >= Y & X <= Y  -> X = Y
# - X >= Y | X <= Y  -> 1
sub _resolve_equality {
  ...
};


1;
