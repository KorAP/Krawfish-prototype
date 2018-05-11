package Krawfish::Koral::Corpus::FieldGroup;
use Role::Tiny::With;
use Krawfish::Log;
use Krawfish::Koral::Corpus::AndNot;
use Krawfish::Koral::Corpus::Anywhere;
use Krawfish::Corpus::Or;
use Krawfish::Corpus::And;
use strict;
use warnings;

with 'Krawfish::Koral::Util::Boolean';
with 'Krawfish::Koral::Util::Relational';
with 'Krawfish::Koral::Util::Ranges';
# TODO: with 'Krawfish::Koral::Util::Regular';
with 'Krawfish::Koral::Corpus';

# TODO:
#   Preparation should be:
#   -> normalize()
#   -> finalize()
#   -> memoize(cache)
#   -> optimize(index)

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


# Mark group as already normalized
sub already_normalized {
  my $self = shift;
  if (@_) {
    $self->{normalized} = shift;
    return $self;
  };
  $self->{normalized};
};


# optimize() is provided by Boolean

sub normalization_order {
  return (
    '_clean_and_flatten',
    '_resolve_inclusivity_and_exclusivity',
    '_resolve_idempotence',
    '_merge_to_date_ranges',
    '_create_open_date_ranges',
    '_resolve_date_subsumption',
    '_resolve_demorgan',
    '_remove_nested_idempotence',
    '_replace_negative'
  );
};


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
  my ($self, $id) = @_;
  my $op = $self->operation eq 'and' ? '&' : '|';

  my $str = $self->is_negative ? '!(' : '';

  $str .= join($op, map {
    $_ ? (
      $_->type eq 'fieldGroup' ?
       (
         $_->is_anywhere ?
           '[1]' :
           '(' . $_->to_string($id) . ')'
         )
       :
       $_->to_string($id)
     ) : '()'
    } @{$self->operands_in_order});

  $str .= $self->is_negative ? ')' : '';
  $str;
};


sub to_sort_string {
  my $self = shift;
  my $str = '';
  my $op = $self->operation eq 'and' ? '&(' : '|(';
  $str .= $self->is_negative ? '!(' : '+(';
  $str .= join(',', map { !$_ ? '()' : $_->to_sort_string } @{$self->operands_in_order});
  $str .= '))';
  return $str;
};

sub from_koral {
  ...
};


1;


__END__

