package Krawfish::Koral::Query::Unique;
use parent 'Krawfish::Koral::Query';
use Krawfish::Query::Unique;
use strict;
use warnings;
use Memoize;
memoize('min_span');
memoize('max_span');

sub new {
  my $class = shift;
  bless {
    operands => [shift]
  }
};

sub to_koral_fragment {
  ...
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
  my ($self, $index) = @_;

  my $span = $self->operand->optimize($index) or return;

  if ($span->max_freq == 0) {
    return $self->builder->nothing;
  };

  return Krawfish::Query::Unique->new($span);
};


sub to_string {
  my $self = shift;
  return 'unique(' . $self->operand->to_string . ')';
};

# TODO: Identical to class

sub is_any {
  $_[0]->operand->is_any;
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


1;
