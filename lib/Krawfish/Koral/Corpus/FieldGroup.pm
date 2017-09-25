package Krawfish::Koral::Corpus::FieldGroup;
use parent ('Krawfish::Koral::Util::Boolean', 'Krawfish::Koral::Corpus');
use Krawfish::Log;
use Krawfish::Koral::Corpus::AndNot;
use Krawfish::Koral::Corpus::Anywhere;

use Krawfish::Corpus::Or;
# use Krawfish::Corpus::OrWithFlags;
use Krawfish::Corpus::And;
# use Krawfish::Corpus::AndWithFlags;
use strict;
use warnings;

# TODO:
#   Preparation should be:
#   -> normalize()
#   -> finalize()
#   -> memoize(cache)
#   -> optimize(index)


# TODO:
#   In normalization phase make
#   X geq Y & X leq Y -> X eq Y

use constant DEBUG => 0;


sub new {
  my $class = shift;
  bless {
    operation => shift,
    operands => [@_]
  }, $class;
};


sub type {
  'fieldGroup';
};


sub operation {
  my $self = shift;
  if (@_) {
    $self->{operation} = shift;
    return $self;
  };
  $self->{operation};
};


# normalize() is provided by Boolean

# optimize() is provided by Boolean

sub bool_and_query {
  my $self = shift;
  Krawfish::Corpus::And->new(
    $_[0],
    $_[1]
  );
};

sub bool_or_query {
  my $self = shift;
  Krawfish::Corpus::Or->new(
    $_[0],
    $_[1]
  );
};

#sub is_anywhere {
#  my $self = shift;
#  return 0 if $self->is_nowhere;
#  return 1 if @{$self->operands} == 0;
#  return 0;
#};

# Check for classes
sub has_classes {
  my $self = shift;

  # Check operands for classes
  foreach (@{$self->operands}) {

    # Has classes
    return 1 if $_->has_classes;
  };
  return;
};


# Return koral
sub to_koral_fragment {
  my $self = shift;
  return {
    '@type' => 'koral:fieldGroup',
    operation => 'operation:' . $self->operation,
    operands => [ map { $_->to_koral_fragment } @{$self->{operands}} ]
  };
};


sub to_string {
  my $self = shift;
  my $op = $self->operation eq 'and' ? '&' : '|';

  my $str = $self->is_negative ? '!(' : '';

  $str .= join($op, map {
    $_ ? (
      $_->type eq 'fieldGroup' ?
       (
         $_->is_anywhere ?
           '[1]' :
           '(' . $_->to_string . ')'
         )
       :
       $_->to_string
     ) : '()'
    } @{$self->operands_in_order});

  $str .= $self->is_negative ? ')' : '';
  $str;
};


1;


__END__

