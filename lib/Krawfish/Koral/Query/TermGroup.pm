package Krawfish::Koral::Query::TermGroup;
use parent 'Krawfish::Koral::Query';
use Krawfish::Koral::Query::Term;
use Krawfish::Query::Or;
use Krawfish::Query::Position;
use Krawfish::Log;
use Scalar::Util qw/blessed/;
use strict;
use warnings;

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
    operands => [@operands]
  }
};

sub type { 'termGroup' };

# TEMPORARILY
sub is_negative {
  0;
};

sub operation {
  $_[0]->{operation};
};

sub operands {
  $_[0]->{operands};
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

sub plan_for {
  my $self = shift;
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
        $query = Krawfish::Query::Position->new(
          MATCHES,
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

sub maybe_unsorted { 0 };

sub is_any {
  my $self = shift;
  return 1 if @{$self->operands} == 0;
  return 0;
};

sub to_string {
  my $self = shift;
  my $op = $self->operation eq 'and' ? '&' : '|';
  join $op, map {
    $_->type eq 'termGroup' ? '(' . $_->to_string . ')' : $_->to_string
  } @{$self->operands};
};

1;
