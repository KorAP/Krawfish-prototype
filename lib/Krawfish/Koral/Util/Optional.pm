package Krawfish::Koral::Util::Optional;
use Role::Tiny;
use Krawfish::Log;
use strict;
use warnings;

# Optional normalization role for
# Krawfish::Koral::Util::Boolean

use constant DEBUG => 0;


# Resolve optionality
# (a|b?|c?) -> (a|b|c)?
sub _resolve_optionality {
  my $self = shift;

  print_log('kq_optional', 'Resolve optionality for ' . $self->to_string) if DEBUG;

  # Either matches nowhere or anywhere
  return if $self->is_nowhere || $self->is_anywhere;

  my $changes = 0;

  # Iterate over operands
  my $opt = 0;
  my @ops;
  foreach my $op (@{$self->operands}) {

    # The operand is optional
    if ($op->is_optional) {

      # Remove optionality
      $op->is_optional(0);
      my $norm = $op->normalize;
      push @ops, $norm ? $norm : $opt;
      $changes++;
    }
    else {
      push @ops, $op;
    };
  };


  return unless $changes;

  # Set operands
  $self->operands(\@ops);

  # In case this query is not yet optional
  unless ($self->is_optional) {
    my $repeat = $self->builder->repeat($self, 0, 1);
    my $repeat_norm = $repeat->normalize;
    return $repeat_norm ? $repeat_norm : $repeat;
  };

  # return;
  return $self;
};


1;
