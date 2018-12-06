package Krawfish::Koral::Query::Or;
use Role::Tiny::With;
use Krawfish::Log;
use Krawfish::Query::Or;
use strict;
use warnings;
use Memoize;
memoize('min_span');
memoize('max_span');

with 'Krawfish::Koral::Util::Boolean';
with 'Krawfish::Koral::Util::Optional';
with 'Krawfish::Koral::Query';

# Or-Construct on spans

# TODO:
#   Deal with optionality in groups!
#   (a|b?|c?) -> (a|b|c)?

use constant DEBUG => 0;

# Constructor
sub new {
  my $class = shift;
  bless {
    operands => [@_]
  }
};

sub type {
  'or'
};

sub operation {
  'or'
};


# Create span-based or-query
sub bool_or_query {
  my $self = shift;
  Krawfish::Query::Or->new(
    $_[0],
    $_[1]
  );
};


# Can't occur per definition
sub bool_and_query {
  return;
};


# Normalize query
# In spans, operands may be optional,
# so this has to be resolved as well.
sub normalization_order {
  return (
    '_clean_and_flatten',
    '_resolve_idempotence',
    '_resolve_demorgan',
    '_remove_nested_idempotence',
    '_wrap_classes',
    '_replace_negative',
    '_resolve_optionality'
  );
};


# Stringification
sub to_string {
  my ($self, $id) = @_;
  return join '|', map { '(' . $_->to_string($id) . ')'} @{$self->operands_in_order};
};


# Get minimum span length in tokens
sub min_span {
  my $self = shift;
  my $ops = $self->operands;

  # Get the smalles min value of all operands
  my $min = $ops->[0]->min_span;
  my $i = 1;
  for (; $i < @$ops; $i++) {
    if ($ops->[$i]->min_span < $min) {
      $min = $ops->[$i]->min_span;
    };
  };
  return $min;
};


# Get the maximum length in tokens
sub max_span {
  my $self = shift;

  my $ops = $self->operands;

  # Get the smalles min value of all operands
  my $max = $ops->[0]->max_span;
  my $i = 1;
  for (; $i < @$ops; $i++) {
    if ($ops->[$i]->max_span > $max) {
      $max = $ops->[$i]->max_span;
    };
  };
  return $max;
};


# Serialization
sub to_koral_fragment {
  my $self = shift;
  return {
    '@type' => 'koral:group',
    'operation' => 'operation:or',
    'operands' => [
      map { $_->to_koral_fragment } @{$self->{operands}}
    ]
  };
};


# Deserialization
sub from_koral {
  my ($class, $kq) = @_;

  my $qb = $class->builder;

  return $class->new(
    map { $qb->from_koral($_) } @{$kq->{operands}}
  );
};


1;
