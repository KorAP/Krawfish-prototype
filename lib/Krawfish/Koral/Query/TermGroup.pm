package Krawfish::Koral::Query::TermGroup;
use parent ('Krawfish::Koral::Util::BooleanTree','Krawfish::Koral::Query');
use Krawfish::Koral::Query::Term;
use Krawfish::Query::Or;
use Krawfish::Query::Constraints;
use Krawfish::Query::Constraint::Position;
use Krawfish::Log;
use Scalar::Util qw/blessed/;
use strict;
use warnings;

# TODO:
#   Preparation should be:
#   -> normalize()
#   -> finalize()
#   -> memoize(cache)
#   -> optimize(index)

use constant DEBUG => 1;


sub new {
  my $class = shift;
  my $operation = shift;

  # Make all operands, terms
  my @operands = map {
    blessed $_ ? $_ : Krawfish::Koral::Query::Term->new($_)
  } @_;

  bless {
    operation => $operation,
    operands => [@operands],
    filter => undef
  }
};

sub type {
  'termGroup'
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
  my $self = shift;
  my $query = $self->builder->exclusion(['matches'], @_);
  print_log('kq_tgroup', 'Create andNot: ' . $query->to_string) if DEBUG;
  $query;
};


sub operation {
  $_[0]->{operation};
};

sub operands {
  my $self = shift;
  if (@_) {
    print_log('kq_tgroup', 'Set operands') if DEBUG;
    $self->{operands} = shift;
  };
  $self->{operands};
};


# Create operands in order
sub operands_in_order {
  my $self = shift;
  my $ops = $self->{operands};
  return [ sort { $a->to_string cmp $b->to_string } @$ops ];
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


# TODO: Flatten or groups in a first pass!
# TODO: In case, the group is 'and' and there is at
#       least one positive element, do for negative elements:
#       [tt/l=Baum & tt/p=NN & cnx/p!=NN]
#       excl(match:pos(match, 'tt/l=Baum', 'tt/p=NN'),'cnx/p=NN')
#       and
#       [tt/l=Baum & tt/p=NN & cnx/p!=NN & cnx/p!=ADJA]
#       excl(match:pos(match, 'tt/l=Baum', 'tt/p=NN'), or('cnx/p=NN', 'cnx/p=ADJA'))
# TODO: der [tt/l=Baum | tt/p=NN | cnx/p!=NN]
#       or(
#         seq(
#           'der',
#            or('tt/l=Baum', 'tt/p=NN')
#         ).
#         ext(
#           'right',
#           excl(
#             'precedes',
#             'der'
#             'cnx/p=NN'
#           ),
#           1
#         )
#       )

# This is rather identical to FieldGroup
sub optimize {
  my ($self, $index) = @_;

    # Get operands in alphabetical order
  my $ops = $self->operands_in_order;

  # Check the frequency of all operands
  # Start with a query != null
  my $i = 0;
  my $first = $ops->[$i];

  print_log('kq_tgroup', 'Initial query is ' . $self->to_string) if DEBUG;

  my $query = $first->optimize($index);
  $i++;

  # Check unless
  while ($query->freq == 0 && $i < @$ops) {
    $first = $ops->[$i++];
    $query = $first->optimize($index);
    $i++;
  };

  if ($self->operation eq 'or') {
    print_log('kq_tgroup', 'Prepare or-group') if DEBUG;

    # Filter out all terms that do not occur
    for (; $i < @$ops; $i++) {

      # Get query operation for next operand
      # TODO: Check for negation!
      my $next = $ops->[$i]->optimize($index);

      if ($next->freq != 0) {

        # TODO: Distinguish here between classes and non-classes!
        $query = Krawfish::Query::Or->new(
          $query,
          $next
        );
      };
    };
  }

  elsif ($self->operation eq 'and') {
    print_log('kq_tgroup', 'Prepare and-group') if DEBUG;

    # Filter out all terms that do not occur
    for (; $i < @$ops; $i++) {

      # Get query operation for next operand
      my $next = $ops->[$i]->optimize($index);

      if ($next->freq != 0) {

        # TODO: Distinguish here between classes and non-classes!
        $query = Krawfish::Query::Constraints->new(
          [Krawfish::Query::Constraint::Position->new(MATCHES)],
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



# TODO:
#   Use Koral::Util::BooleanTree
sub plan_for {
  my $self = shift;

  warn 'DEPRECATED';

  my $index = shift;
  my $ops = $self->operands;

  # if (@$ops == 0) {
  #   return Krawfish::Koral::Query::Nothing->new;
  # };

  my @negatives = ();

  # First pass - flatten and cleanup
  for (my $i = @$ops - 1; $i >= 0;) {

    # Clean null
    if ($ops->[$i]->is_null) {
      splice @$ops, $i, 1;
    }

    # Flatten groups
    elsif ($ops->[$i]->type eq 'termGroup' &&
             $ops->[$i]->operation eq $self->operation) {
      my $operands = $ops->[$i]->operands;
      my $nr = @$operands;
      splice @$ops, $i, 1, @$operands;
      $i+= $nr;
    }

    # Element is negative - remember
    elsif ($ops->[$i]->is_negative) {
      push @negatives, splice @$ops, $i, 1
    };

    $i--
  };


  # No positive operator valid
  if (@$ops == 0) {
    $self->error(000, 'Negative queries are not supported');
    return;
  }

  # Only one positive operator - simplify
  elsif (@$ops == 1 && @negatives == 0) {
    my $single_op = $ops->[0]->plan_for($index);

    if ($single_op->freq == 0) {
      return Krawfish::Query::Nothing->new;
    };

    # Return operand query
    return $single_op;
  };

  my $i = 0;

  # Check the frequency of all operands
  # Start with a query != null
  my $query = $ops->[$i++]->plan_for($index);

  while ($query->freq == 0 && $i < @$ops) {
    $query = $ops->[$i++]->plan_for($index);
  };

  # Serialize for 'or' operation
  if ($self->operation eq 'or') {

    print_log('kq_tgroup', 'Prepare or-group') if DEBUG;

    # Filter out all terms that do not occur
    for (; $i < @$ops; $i++) {
      my $option = $ops->[$i]->plan_for($index);
      if ($option->freq != 0) {
        $query = Krawfish::Query::Or->new(
          $query,
          $option
        )
      };
    };
  }

  # Serialize for 'and' operation
  else {

    print_log('kq_tgroup', 'Prepare and-group') if DEBUG;

    # TODO: Order by frequency!
    for (; $i < @$ops; $i++) {
      my $option = $ops->[$i]->plan_for($index);

      if ($option->freq != 0) {
        $query = Krawfish::Query::Constraints->new(
          [Krawfish::Query::Constraint::Position->new(MATCHES)],
          $query,
          $option
        );
      };
    };
  };

  if ($query->freq == 0) {
    return Krawfish::Query::Nothing->new;
  };

  # Merge the remembered negatives
  if (@negatives) {
    if ($self->operation eq 'and') {

      print_log('kq_tgroup', 'Add negatives to and-group') if DEBUG;

      # Plan query with positivie element
      # TODO: Elements may be termgroups!
      # TODO: Elements may have frequency zero
      my $neg_query =
        pop(@negatives)->match('=')->plan_for($index);

      # Join all negative terms in an or-query
      foreach (@negatives) {
        my $option = $_->match('=')->plan_for($index);

        if ($option->freq != 0) {
          $neg_query = Krawfish::Query::Or->new(
            $neg_query,
            $option
          )
        };
      };

      # Negation not important
      if ($neg_query->freq == 0) {
        return $query;
      };

      # Exclude this
      $query = Krawfish::Query::Exclusion->new(
        MATCHES,
        $query,
        $neg_query
      );
    }
    else {
      ...
    }
  };

  return $query;
};

# Filter by corpus
sub filter_by {
  my $self = shift;
  $self->{filter} = shift;
};


sub maybe_unsorted { 0 };

#sub is_any {
#  my $self = shift;
  # return 0 if $self->is_nothing;
  # return 1 if @{$self->operands} == 0;
#  return $self->{any};
#};

sub to_string {
  my $self = shift;
  my $op = $self->operation eq 'and' ? '&' : '|';
  join $op, map {
    $_->type eq 'termGroup' ? '(' . $_->to_string . ')' : $_->to_string
  } @{$self->operands};
};

1;
