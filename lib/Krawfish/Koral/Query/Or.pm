package Krawfish::Koral::Query::Or;
use parent ('Krawfish::Koral::Util::Boolean','Krawfish::Koral::Query');
use Krawfish::Log;
use Krawfish::Query::Or;
use strict;
use warnings;
use Memoize;
memoize('min_span');
memoize('max_span');

# Or-Construct on spans

# TODO:
#   Deal with optionality in groups!
#   (a|b?|c?) -> (a|b|c)?

use constant DEBUG => 1;

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
sub normalize {
  my $self = shift;
  return $self->SUPER::normalize
    ->_resolve_optionality;
};


# Resolve optionality
# (a|b?|c?) -> (a|b|c)?
sub _resolve_optionality {
  my $self = shift;
  print_log('kq_span_or', 'Resolve optionality for ' . $self->to_string) if DEBUG;

  # Either matches nowhere or anywhere
  return $self if $self->is_nowhere || $self->is_anywhere;

  # Iterate over operands
  my $opt = 0;
  my @ops;
  foreach my $op (@{$self->operands}) {

    # The operand 
    if ($op->is_optional) {

      # Remove optionality
      $op->is_optional(0);
      push @ops, $op->normalize;
      $opt = 1;
    }
    else {
      push @ops, $op;
    };
  };


  if ($opt) {
    # Set operands
    $self->operands(\@ops);

    # In case this query is not yet optional
    unless ($self->is_optional) {
      return $self->builder->repeat($self, 0, 1)->normalize;
    };
  };

  return $self;
};


# Stringification
sub to_string {
  my $self = shift;
  return join '|', map { '(' . $_->to_string . ')'} @{$self->operands_in_order};
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

1;
