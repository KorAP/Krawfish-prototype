package Krawfish::Koral::Corpus::FieldGroup;
use parent ('Krawfish::Koral::Util::Boolean', 'Krawfish::Koral::Corpus');
use Krawfish::Log;
use Krawfish::Koral::Corpus::AndNot;
use Krawfish::Koral::Corpus::Any;

use Krawfish::Corpus::Or;
use Krawfish::Corpus::OrWithFlags;
use Krawfish::Corpus::And;
use Krawfish::Corpus::AndWithFlags;

# TODO: Rename to AndNot()
use Krawfish::Corpus::Without;
use strict;
use warnings;

# TODO:
#   Preparation should be:
#   -> normalize()
#   -> finalize()
#   -> memoize(cache)
#   -> optimize(index)

# TODO: Sort operands by frequency -
#   but for signaturing, sort them
#   alphabetically (probably)

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


sub build_or {
  shift;
  __PACKAGE__->new('or',@_);
};


sub build_and {
  shift;
  __PACKAGE__->new('and', @_);
};


# Build AndNot group
sub build_and_not {
  shift;

  # This can't be replaced with FieldGroup and an andNot operation
  # because operand order is important with AndNot
  Krawfish::Koral::Corpus::AndNot->new(@_);
};


sub build_any {
  shift;
  Krawfish::Koral::Corpus::Any->new;

  # TODO: May as well be
  # my $any = Krawfish::Koral::Corpus::FieldGroup->new;
  # $any->is_any(1);
  # return $any;
};


sub operands {
  my $self = shift;
  if (@_) {
    print_log('kq_fgroup', 'Set operands') if DEBUG;
    $self->{operands} = shift;
  };
  return $self->{operands};
};


# Create operands in order
sub operands_in_order {
  my $self = shift;
  my $ops = $self->{operands};
  return [ sort { ($a && $b) ? ($a->to_string cmp $b->to_string) : 1 } @$ops ];
};


# normalize() is provided by BooleanTree

# Optimize for an index
sub optimize {
  my ($self, $index) = @_;

  # Get operands in alphabetical order
  my $ops = $self->operands_in_order;

  # Check the frequency of all operands
  # Start with a query != null
  my $i = 0;
  my $first = $ops->[$i];

  print_log('kq_fgroup', 'Initial query is ' . $self->to_string) if DEBUG;

  my $query = $first->optimize($index);
  $i++;

  # Check unless
  while ($query->max_freq == 0 && $i < @$ops) {
    $first = $ops->[$i++];
    $query = $first->optimize($index);
    $i++;
  };

  if ($self->operation eq 'or') {
    print_log('kq_fgroup', 'Prepare or-group') if DEBUG;

    # Filter out all terms that do not occur
    for (; $i < @$ops; $i++) {

      # Get query operation for next operand
      # TODO: Check for negation!
      my $next = $ops->[$i]->optimize($index);

      if ($next->max_freq != 0) {

        # TODO: Distinguish here between classes and non-classes!
        $query = Krawfish::Corpus::Or->new(
          $query,
          $next
        );
      };
    };
  }
  elsif ($self->operation eq 'and') {
    print_log('kq_fgroup', 'Prepare and-group') if DEBUG;

    # Filter out all terms that do not occur
    for (; $i < @$ops; $i++) {

      # Get query operation for next operand
      my $next = $ops->[$i]->optimize($index);

      if ($next->max_freq != 0) {

        # TODO: Distinguish here between classes and non-classes!
        $query = Krawfish::Corpus::And->new(
          $query,
          $next
        );
      }

      # One operand is not existing
      else {
        return Krawfish::Query::Nothing->new;
      };
    };
  }
  else {
    warn 'Should never happen!';
  };

  if ($query->max_freq == 0) {
    return Krawfish::Query::Nothing->new;
  };

  return $query;
};


#sub is_any {
#  my $self = shift;
#  return 0 if $self->is_nothing;
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
         $_->is_any ?
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

