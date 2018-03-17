package Krawfish::Koral::Util::Regular;
use Role::Tiny;
use Krawfish::Log;
use strict;
use warnings;

# Optional normalization role for
# Krawfish::Koral::Util::Boolean

# TODO:
#   For the moment, this is defunct

# Resolve optionality
# /^QAO-NC.*$/ | /^QAO-XY.*$/ -> /^QAO-(NC|XY).*$/
sub _combine_regex {
  my $self = shift;

  print_log('kq_regular', 'Combine regex for ' . $self->to_string) if DEBUG;

  # Either matches nowhere or anywhere
  return if $self->is_nowhere || $self->is_anywhere;

  # Combining regex with AND can be the opposite of
  # simple - so it probably should be ignored
  return if $self->operation eq 'or';

  # Temporary: DO NOTHING
  return;

  my $changes = 0;

  my $ops = $self->operands_in_order;

  for (my $i = 1; $i < scalar(@$ops); $i++) {
    my ($op_a, $op_b) = ($ops->[$i-1], $ops->[$i]);

    if ($op_a->is_leaf && $op_b->is_leaf &&
          $op_a->key_type eq 'regex' &&
          $op_a->key_type eq $op_a->key_type) {
      ...;
      $changes++;
    };
  };

  return unless $changes;
  $self->operands($ops);
  return $self;
};


1;
