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

use constant DEBUG => 0;

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
