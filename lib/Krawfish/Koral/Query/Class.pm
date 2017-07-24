package Krawfish::Koral::Query::Class;
use parent 'Krawfish::Koral::Query';
use Krawfish::Query::Class;
use strict;
use warnings;

use constant {
  DEBUG => 1
};

sub new {
  my $class = shift;
  bless {
    operands => [shift],
    number => shift
  }, $class;
};

sub to_koral_fragment {
  my $self = shift;
  return {
    '@type' => 'koral:group',
    'operation' => 'operation:class',
    'classOut' => $self->number,
    'operands' => [
      $self->operand->to_koral_fragment
    ]
  };
};

sub type { 'class' };


# Remove classes passed as an array references
sub remove_classes {
  my ($self, $keep) = @_;
  unless ($keep) {
    $keep = [];
  };

  $self->{operand}->[0] = $self->{operands}->[0]->remove_classes($keep);

  foreach (@$keep) {
    if ($_ eq $self->{number}) {
      return $self;
    };
  };

  # Return the span only
  return $self->{operands}->[0];
};

# A class always spans its operand span
sub min_span {
  $_[0]->operand->min_span;
};


# A class always spans its operand span
sub max_span {
  $_[0]->operand->max_span;
};


# Normalize the class query
sub normalize {
  my $self = shift;

  # Normalize the span
  my $span;
  unless ($span = $self->operand->normalize) {
    $self->copy_info_from($self->operand);
    return;
  };

  # Ignore class if span is negative
  return $span if $span->is_negative;

  # Readd the span
  $self->operand($span);
  return $self;
};


# Treat the query as if it is root
sub finalize {
  my $self = shift;

  my $span;
  unless ($span = $self->operand->finalize) {
    $self->copy_info_from($self->operand);
    return;
  };

  $self->operand($span);
  return $self;
};


# Optimize on index
sub optimize {
  my ($self, $index) = @_;

  my $span = $self->operand->optimize($index);

  # Span has no match
  if ($span->max_freq == 0) {
    return $self->builder->nothing;
  };

  return Krawfish::Query::Class->new(
    $span,
    $self->number
  );
};


# Iterate over all subqueries and replace them
# if necessary
#sub replace_subqueries {
#  my ($self, $cb) = @_;
#
#  # Check if the subspan should be replaced
#  if (my $replace = $cb->($self->operand)) {
#
#    # Replace
#    $self->{span} = $replace;
#  };
#};



sub to_string {
  my $self = shift;
  my $str = '{';
  $str .= $self->number . ':' if $self->number;
  return $str . $self->operand->to_string . '}';
};


sub number {
  $_[0]->{number};
};


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
  my $self = shift;
  my $span = $self->operand;
  if (@_) {
    $span->is_negative(@_);
    return $self;
  };
  return $span->is_negative;
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


sub maybe_unsorded {
  $_[0]->operand->maybe_unsorted;
};


sub is_classed { 1 };


sub from_koral {
  my ($class, $kq) = @_;
  my $importer = $class->importer;

  my $nr = $kq->{'classOut'} or warn 'No class defined';

  # Import operand
  my $op = $importer->all($kq->{operands}->[0]);

  return $class->new($op, $nr);
};


1;
