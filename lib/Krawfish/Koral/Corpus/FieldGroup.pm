package Krawfish::Koral::Corpus::FieldGroup;
use parent ('Krawfish::Koral::Util::BooleanTree', 'Krawfish::Koral::Corpus');
use Krawfish::Log;
use Krawfish::Koral::Corpus::AndNot;
use Krawfish::Koral::Corpus::Any;

use Krawfish::Corpus::Or;
use Krawfish::Corpus::OrWithFlags;
use Krawfish::Corpus::And;
use Krawfish::Corpus::AndWithFlags;

# TODO: Rename to AndNot()
use Krawfish::Corpus::Without;
use Krawfish::Corpus::Negation;
use Krawfish::Corpus::All;
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

use constant DEBUG => 1;


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
  $_[0]->{operation};
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


sub toggle_operation {
  my $self = shift;
  if ($self->{operation} eq 'or') {
    $self->{operation} = 'and';
  }
  elsif ($self->{operation} eq 'and') {
    $self->{operation} = 'or';
  };
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
  while ($query->freq == 0 && $i < @$ops) {
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

      if ($next->freq != 0) {

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

      if ($next->freq != 0) {

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

  if ($query->freq == 0) {
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

# Deprecated
sub plan_for {
  my ($self, $index) = @_;

  warn 'DEPRECATED! Replace with ->normalize->memoize->optimize';

  if (DEBUG) {
    print_log('kq_fgroup', 'Prepare group') if DEBUG;
  };


  # Get operands in alphabetical order
  my $ops = $self->operands_in_order;

  # Has classes
  my $has_classes = $self->has_classes;

  my $i = 0;

  # Check the frequency of all operands
  # Start with a query != null
  my $first = $ops->[$i];
  my $query_neg = $self->is_negative;

  # First operand is negative - remember this
#  if ($query_neg) {
#
#    # Set to positive
#    $first->is_negative(0);
#  };

  my $query = $first->plan_for($index);
  $i++;

  # Check unless
  while ($query->freq == 0 && $i < @$ops) {
    $first = $ops->[$i++];
    $query = $first->plan_for($index);
    $query_neg = $first->is_negative;
    $i++;
  };

  # serialize for 'or' operation
  if ($self->operation eq 'or') {

    print_log('kq_fgroup', 'Prepare or-group') if DEBUG;

    my $option_neg = 0;

    # Filter out all terms that do not occur
    for (; $i < @$ops; $i++) {

      # Get query operation for next operand
      # TODO: Check for negation!
      my $next = $ops->[$i]->plan_for($index);

      # Check for itempotence
      if ($query->to_string eq $next->to_string) {
        print_log('kq_fgroup', 'Subcorpora are idempotent') if DEBUG;
        next;
      };

      if ($next->freq != 0) {

        if ($query_neg) {
          warn '****';
        };

        # Create group with classes
        if ($has_classes) {
          $query = Krawfish::Corpus::OrWithFlags->new(
            $query,
            $next
          )
        }

        # Create group without classes
        else {
          $query = Krawfish::Corpus::Or->new(
            $query,
            $next
          )
        };
      };
    };
  }


  # Create 'and'-group
  elsif ($self->operation eq 'and') {

    print_log('kq_fgroup', 'Prepare and-group') if DEBUG;

    my $option_neg = 0;

    # Filter out all terms that do not occur
    for (; $i < @$ops; $i++) {

      my $next = $ops->[$i];

      # The next operand
      $option_neg = $next->is_negative;

      # Second operand is negative - remember this
      if ($option_neg) {

        # Set to positive
        $next->is_negative(0);
      };


      # Plan option
      my $option = $next->plan_for($index);


      # Check for itempotence
      if ($query->to_string eq $option->to_string) {
        print_log('kq_fgroup', 'Subcorpora are idempotent') if DEBUG;
        next;
      };

      # Do not add useless options
      # TODO: What if it is part of a negation???
      next if $option->freq == 0;

      # Both operands are negative
      if ($query_neg || $option_neg) {

        # Both operands are negative
        if ($query_neg && $option_neg) {

          # Create group with classes
          if ($has_classes) {
            $query = Krawfish::Corpus::OrWithFlags->new(
              $query,
              $option
            );
          }


          # Create group without classes
          else {
            $query = Krawfish::Corpus::Or->new(
              $query,
              $option
            );
          };
          $query_neg = 1;
        }

        # Option is negative
        elsif ($option_neg) {

          if ($has_classes) {
            warn 'Not yet supported for classes';
          };

          $query = Krawfish::Corpus::Without->new(
            $query,
            $option
          );
          $query_neg = 0;
        }

        # Base query is negative - reorder query
        else {

          if ($has_classes) {
            warn 'Not yet supported for classes';
          };

          $query = Krawfish::Corpus::Without->new(
            $option,
            $query
          );
          $query_neg = 0;
        };
      }

      # No negative query
      else {

        # Create group with classes
        if ($has_classes) {
          $query = Krawfish::Corpus::AndWithFlags->new(
            $query,
            $option
          );
        }

        # Create group without classes
        else {
          $query = Krawfish::Corpus::And->new(
            $query,
            $option
          );
        };

      };
    };
  };

  if ($query->freq == 0) {
    return Krawfish::Query::Nothing->new unless $query_neg;

    # Return all non-deleted docs
    return Krawfish::Corpus::All->new($index);
  }

  # Negate result
  elsif ($query_neg) {
    $query = Krawfish::Corpus::Negation->new($index, $query);
  };

  return $query;
};
