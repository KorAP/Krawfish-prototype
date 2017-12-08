package Krawfish::Koral::Query::Class;
use Role::Tiny::With;
use Krawfish::Query::Class;
use Krawfish::Log;

use constant DEBUG => 0;

with 'Krawfish::Koral::Query';

use Memoize;

memoize('min_span');
memoize('max_span');


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


# Optimize on segment
sub optimize {
  my ($self, $segment) = @_;

  my $span = $self->operand->optimize($segment);

  # Span has no match
  if ($span->max_freq == 0) {
    return $self->builder->nowhere;
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
  my $op = $importer->from_koral($kq->{operands}->[0]);

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
