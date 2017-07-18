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

# TODO: Make this part of plan_for
#sub replace_references {
#  my ($self, $refs) = @_;
#  my $sig = $self->signature;
#
#  # Subquery is identical to given query
#  if ($refs->{$sig}) {
#    ...
#  }
#  else {
#    $refs->{$sig} = $self->span;
#  };
#};


# Remove classes passed as an array references
sub remove_classes {
  my ($self, $keep) = @_;
  unless ($keep) {
    $keep = [];
  };

  $self->{span} = $self->{span}->remove_classes($keep);

  foreach (@$keep) {
    if ($_ eq $self->{number}) {
      return $self;
    };
  };

  # Return the span only
  return $self->{span};
};


# Normalize the class query
sub normalize {
  my $self = shift;

  # Normalize the span
  my $span;
  unless ($span = $self->span->normalize) {
    $self->copy_info_from($self->span);
    return;
  };

  # Ignore class if span is negative
  return $span if $span->is_negative;

  # Readd the span
  $self->span($span);
  return $self;
};


# Treat the query as if it is root
sub finalize {
  my $self = shift;

  my $span;
  unless ($span = $self->span->finalize) {
    $self->copy_info_from($self->span);
    return;
  };

  $self->span($span);
  return $self;
};


# Optimize on index
sub optimize {
  my ($self, $index) = @_;

  my $span = $self->span->optimize($index);

  # Span has no match
  if ($span->freq == 0) {
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
#  if (my $replace = $cb->($self->span)) {
#
#    # Replace
#    $self->{span} = $replace;
#  };
#};


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
  if (@_ == 2) {
    $_[0]->{span} = $_[1];
  };
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
  my $self = shift;
  my $span = $self->span;
  if (@_) {
    $span->is_negative(@_);
    return $self;
  };
  return $span->is_negative;
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
