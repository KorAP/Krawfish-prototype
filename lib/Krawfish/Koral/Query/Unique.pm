package Krawfish::Koral::Query::Unique;
use Role::Tiny::With;
use Krawfish::Query::Unique;
use strict;
use warnings;
use Memoize;
memoize('min_span');
memoize('max_span');

with 'Krawfish::Koral::Query';

sub new {
  my $class = shift;
  bless {
    operands => [shift]
  }
};


sub type { 'unique' };


# Normalize unique query
sub normalize {
  my $self = shift;

  my $span;
  unless ($span = $self->operand->normalize) {
    $self->copy_info_from($self->operand);
    return;
  };

  $self->operands([$span]);

  return $self;
};


# Optimize unique query
sub optimize {
  my ($self, $segment) = @_;

  my $span = $self->operand->optimize($segment) or return;

  if ($span->max_freq == 0) {
    return $self->builder->nowhere;
  };

  return Krawfish::Query::Unique->new($span);
};


sub to_string {
  my $self = shift;
  return 'unique(' . $self->operand->to_string . ')';
};

# TODO: Identical to class

sub is_anywhere {
  $_[0]->operand->is_anywhere;
};

sub is_optional {
  $_[0]->operand->is_optional;
};

sub is_null {
  $_[0]->operand->is_null;
};

sub is_negative {
  $_[0]->operand->is_negative;
};

sub is_extended {
  $_[0]->operand->is_extended;
};

sub is_extended_right {
  $_[0]->operand->is_extended_right;
};

sub is_extended_left {
  $_[0]->operand->is_extended_left;
};

sub is_classed {
  $_[0]->operand->is_classed;
};

sub maybe_unsorted {
  $_[0]->operand->maybe_unsorted;
};

# A unique query always spans its operand span
sub min_span {
  $_[0]->operand->min_span;
};


# A unique query always spans its operand span
sub max_span {
  $_[0]->operand->max_span;
};


# serialize
sub to_koral_fragment {
  my $self = shift;
  return {
    '@type' => 'koral:group',
    'operation' => 'operation:unique',
    'operands' => [
      $self->operand->to_koral_fragment
    ]
  };
};


# Deserialize
sub from_koral {
  my ($class, $kq) = @_;
  my $op = $kq->{operands}->[0];
  return $class->new(
    $class->importer->from_koral($op)
  );
};


1;
