package Krawfish::Koral::Query::Sequence;
use Role::Tiny::With;
use Krawfish::Log;
use strict;
use warnings;
use Memoize;
memoize('min_span');
memoize('max_span');

with 'Krawfish::Koral::Util::Sequential';
with 'Krawfish::Koral::Query';

# TODO:
#   Check for queries like "Der {[pos!=ADJ]*} Mann"

# TODO:
#   Make problem solving a separate class in
#   Krawfish::Koral::Util::Sequence, similar to the Boolean stuff!
#   Also: Split this in a serializable logical node phase and an index
#   bound segment phase!

# TODO:
#   Negative extensions are succeedsDirectly-exclusions wrapped in
#   an extension.

# TODO:
#   Take care of punctuations in sequences (as the have different
#   position information) -> [corenlp/p=N][.]

use constant DEBUG => 0;


sub new {
  my $class = shift;
  my $self = Krawfish::Koral::Query::new($class);
  $self->{operands} = [@_];
  $self->{info} = undef;
  $self->{_checked} = 0;
  $self->{anywhere} = 1;
  $self->{null} = 1;
  $self->{maybe_unsorted} = 0;
  return $self;
};


# Get number of operands
sub size {
  scalar @{$_[0]->operands};
};


sub type { 'sequence' };


# Check for properties
sub _check {
  my $self = shift;

  return if $self->{_checked};

  if (DEBUG) {
    print_log('kq_seq', 'Check ' . $self->to_string . ' with ' . (@{$self->operands}) . ' operands');
  };

  # Check all operands
  foreach (@{$self->operands}) {

    if (DEBUG) {
      print_log('kq_seq', 'Check operand ' . $_->to_string);
    };

    # If one operand is set - return null
    unless ($_->is_null) {
      $self->{null} = 0;
    };

    unless ($_->is_anywhere) {
      $self->{anywhere} = 0;
    };

    if ($_->maybe_unsorted) {
      $self->{maybe_unsorted} = 1;
    };

    if (DEBUG) {
      print_log('kq_seq', 'Operand ' . $_->to_string . ' is checked');
    };
  };

  $self->{_checked} = 1;
};


sub is_anywhere {
  my $self = shift;
  $self->_check;
  print_log('kq_seq', 'Check for anywhere: ' . $self->to_string . ' is ' . $self->{anywhere}) if DEBUG;
  return $self->{anywhere};
};


sub is_null {
  my $self = shift;
  $self->_check;
  return $self->{null};
};


sub maybe_unsorted {
  my $self = shift;
  $self->_check;
  return $self->{maybe_unsorted};
};


# A sequence is the sum of all operands' lengths
sub min_span {
  my $self = shift;
  $self->_check;
  my $min = 0;
  foreach my $op (@{$self->operands}) {
    $min += $op->min_span;
  };
  return $min;
};


# A sequence is the sum of all operands' lengths
sub max_span {
  my $self = shift;
  $self->_check;
  my $max = 0;
  foreach my $op (@{$self->operands}) {

    # In case one operand has an arbitrary length,
    # return the arbitrary length
    return -1 if $op->max_span == -1;
    $max += $op->max_span;
  };
  return $max;
};


# Serialization
sub to_koral_fragment {
  my $self = shift;
  return {
    '@type' => 'koral:group',
    'operation' => 'operation:sequence',
    'operands' => [
      map { $_->to_koral_fragment } @{$self->{operands}}
    ]
  };
};


# Stringification
sub to_string {
  my ($self, $id) = @_;
  return join '', map { $_->to_string($id) } @{$self->operands};
};


# Get from koralquery
# TODO:
#   Support further constraints!
sub from_koral {
  my ($class, $kq) = @_;

  my $qb = $class->builder;

  return $class->new(
    map { $qb->from_koral($_) } @{$kq->{operands}}
  );
};


1;


__END__
