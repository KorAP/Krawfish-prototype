package Krawfish::Koral::Query::Sequence;
use parent ('Krawfish::Koral::Util::Sequential','Krawfish::Koral::Query');
use Krawfish::Log;
use strict;
use warnings;

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
#   Rename array to operands!

use constant DEBUG => 0;


sub new {
  my $class = shift;
  my $self = $class->SUPER::new;
  $self->{operands} = [@_];
  $self->{info} = undef;
  $self->{_checked} = 0;
  $self->{any} = 1;
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

  # Check all operands
  foreach (@{$self->operands}) {

    # If one operand is set - return null
    unless ($_->is_null) {
      $self->{null} = 0;
      $self->{any} = 0;
    };

    unless ($_->is_any) {
      $self->{any} = 0;
    };

    if ($_->maybe_unsorted) {
      $self->{maybe_unsorted} = 1;
    };
  };

  $self->{_checked} = 1;
};

sub is_any {
  my $self = shift;
  $self->_check;
  return $self->{any};
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
# TODO: memoize
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
# TODO: memoize
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


sub to_string {
  my $self = shift;
  return join '', map { $_->to_string } @{$self->operands};
};


sub from_koral {
  my $class = shift;
  my $kq = shift;

  my $importer = $class->importer;

  return $class->new(
    map { $importer->all($_) } @{$kq->{operands}}
  );
};


1;


__END__
