package Krawfish::Koral::Query::Class;
use parent 'Krawfish::Koral::Query';
use Krawfish::Query::Class;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless {
    span => shift,
    number => shift
  }
};

sub to_koral_fragment {
  my $self = shift;
  return {
    '@type' => 'koral:group',
    'operation' => 'operation:class',
    'classOut' => $self->number,
    'operands' => [
      $self->span->to_koral_fragment
    ]
  };
};

sub type { 'class' };

sub plan_for {
  my ($self, $index) = @_;

  my $span;
  unless ($span = $self->span->plan_for($index)) {
    $self->copy_info_from($self->span);
    return;
  };

  # Span has no match
  if ($span->freq == 0) {
    return $self->builder->nothing;
  };

  return Krawfish::Query::Class->new(
    $span,
    $self->number
  );
};

sub filter_by {
  my $self = shift;
  $self->span->filter_by(shift);
};

sub to_string {
  my $self = shift;
  my $str = '{';
  $str .= $self->number . ':' if $self->number;
  return $str . $self->span->to_string . '}';
};

sub span {
  $_[0]->{span};
};

sub number {
  $_[0]->{number};
};

sub is_any {
  $_[0]->span->is_any;
};

sub is_optional {
  $_[0]->span->is_optional;
};

sub is_null {
  $_[0]->span->is_null;
};

sub is_negative {
  $_[0]->span->is_negative;
};

sub is_extended {
  $_[0]->span->is_extended;
};

sub is_extended_right {
  $_[0]->span->is_extended_right;
};

sub is_extended_left {
  $_[0]->span->is_extended_left;
};

sub maybe_unsorded {
  $_[0]->span->maybe_unsorted;
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
