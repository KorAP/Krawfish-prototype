package Krawfish::Koral::Query::Class;
use Role::Tiny::With;
use Krawfish::Query::Class;
use Krawfish::Query::Nowhere;
use Krawfish::Log;

use constant DEBUG => 0;

with 'Krawfish::Koral::Query::Proxy';
with 'Krawfish::Koral::Query';


# Constructor
sub new {
  my $class = shift;

  bless {
    operands => [shift],
    number => shift // 1
  }, $class;
};


sub type { 'class' };


# Remove classes passed as an array references
sub remove_classes {
  my ($self, $keep) = @_;
  unless ($keep) {
    $keep = [];
  };

  if (DEBUG) {
    print_log('kq_q_class', 'Remove classes from ' . $self->to_string);
  };

  $self->{operand}->[0] = $self->{operands}->[0]->remove_classes($keep);

  # Check the keep operand
  foreach (@$keep) {
    if ($_ eq $self->number) {
      return $self;
    };
  };

  if (DEBUG) {
    print_log('kq_q_class', 'Remove own class ' . $self->number);
  };

  # Return the span only
  return $self->operand;
};


# Return defined classes
sub defined_classes {
  my $self = shift;

  return [
    @{$self->operand->defined_classes},
    $self->number
  ];
};


# Normalize the class query
sub normalize {
  my $self = shift;

  # Sort based on numbers
  while ($self->operand->type eq 'class') {

    # Get nested class
    my $class = $self->operand;

    # Remove irrelevant class
    if ($self->number == $class->number) {
      $self->operand($class->operand);
    }

    # Switch numbers
    elsif ($self->number < $self->operand->number) {
      my $number = $self->number;
      $self->number($self->operand->number);
      $self->operand->number($number);
    }

    # Last
    else {
      last;
    };
  };

  # Normalize the span
  my $span;
  unless ($span = $self->operand->normalize) {
    $self->move_info_from($self->operand);
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


# Optimize on segment
sub optimize {
  my ($self, $segment) = @_;

  my $span = $self->operand->optimize($segment);

  # Span has no match
  if ($span->max_freq == 0) {
    return Krawfish::Query::Nowhere->new;
  };

  return Krawfish::Query::Class->new(
    $span,
    $self->number
  );
};


# Stringification
sub to_string {
  my ($self, $id) = @_;
  my $str = '{';
  $str .= $self->number . ':' if $self->number;
  return $str . $self->operand->to_string($id) . '}';
};


sub number {
  if (defined $_[1]) {
    $_[0]->{number} = $_[1];
    return $_[0];
  };
  $_[0]->{number};
};


# Get or set negativity
sub is_negative {
  my $self = shift;
  my $span = $self->operand;
  if (@_) {
    $span->is_negative(@_);
    return $self;
  };
  return $span->is_negative;
};


# Class queries are always classed
sub is_classed {
  1;
};


# TODO:
#   Currently supports classOut only
sub from_koral {
  my ($class, $kq) = @_;
  my $qb = $class->builder;

  my $nr = $kq->{'classOut'} // 1;

  # Import operand
  my $op = $qb->from_koral($kq->{operands}->[0]);

  return $class->new($op, $nr);
};


# Serialize to KoralQuery
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


1;
