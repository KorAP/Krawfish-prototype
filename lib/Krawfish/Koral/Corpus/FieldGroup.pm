package Krawfish::Koral::Corpus::FieldGroup;
use parent 'Krawfish::Koral::Corpus';
use Krawfish::Log;
use Krawfish::Corpus::Or;
use Krawfish::Corpus::OrWithFlags;
use Krawfish::Corpus::And;
use Krawfish::Corpus::AndWithFlags;
use Krawfish::Corpus::Without;
use Krawfish::Corpus::Negation;
use Krawfish::Corpus::All;
use strict;
use warnings;

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

sub operands {
  $_[0]->{operands}
};

# Create operands in order
sub operands_in_order {
  my $self = shift;
  my $ops = $self->{operands};
  return [ sort { $a->to_string cmp $b->to_string } @$ops ];
};

sub is_negative {
  my $self = shift;
  foreach (@{$self->operands}) {
    return unless $_->is_negative;
  };
  return 1;
};

# Check https://de.wikipedia.org/wiki/Boolesche_Algebra
# for optimizations
# TODO:
#    and(a,a) -> a ; or(a,a) -> a
#    or(and(a,b),and(a,c)) -> and(a,or(b,c))
#    and(or(a,b),or(a,c)) -> or(a,and(b,c))
#    not(not(a)) -> a
#    and(a,or(a,b)) -> a
#    or(a,and(a,b)) -> a

# DeMorgan:
#    or(not(a),not(b))  -> not(and(a,b))
#    and(not(a),not(b)) -> not(or(a,b))

# TODO:
#   from managing gigabytes bool_optimiser.c
#/* =========================================================================
# * Function: OptimiseBoolTree
# * Description: 
# *      For case 2:
# *        Do three major steps:
# *        (i) put into standard form
# *            -> put into DNF (disjunctive normal form - or of ands)
# *            Use DeMorgan's, Double-negative, Distributive rules
# *        (ii) simplify
# *             apply idempotency rules
# *        (iii) ameliorate
# *              convert &! to diff nodes, order terms by frequency,...
# *     Could also do the matching idempotency laws i.e. ...
# *     (A | A), (A | !A), (A & !A), (A & A), (A & (A | B)), (A | (A & B)) 
# *     Job for future.... ;-) 
# * Input: 
# * Output: 
# * ========================================================================= */
#/* =========================================================================
# * Function: DoubleNeg
# * Description: 
# *      !(!(a) = a
# *      Assumes binary tree.
# * Input: 
# * Output: 
# * ========================================================================= */
#/* =========================================================================
# * Function: AndDeMorgan
# * Description: 
# *      DeMorgan's rule for 'not' of an 'and'  i.e. !(a & b) <=> (!a) | (!b)
# *      Assumes Binary Tree
# * Input: 
# *      not of and tree
# * Output: 
# *      or of not trees
# * ========================================================================= */
#/* =========================================================================
# * Function: OrDeMorgan
# * Description: 
# *      DeMorgan's rule for 'not' of an 'or' i.e. !(a | b) <=> (!a) & (!b)
# *      Assumes Binary Tree
# * Input: 
# *      not of and tree
# * Output: 
# *      or of not trees
# * ========================================================================= */
#/* =========================================================================
# * Function: PermeateNots
# * Description: 
# *      Use DeMorgan's and Double-negative
# *      Assumes tree in binary form (i.e. No ands/ors collapsed)
# * Input: 
# * Output: 
# * ========================================================================= */
#/* =========================================================================
# * Function: AndDistribute
# * Description: 
# *      (a | b) & A <=> (a & A) | (b & A)
# * Input: 
# *      binary tree of "AND" , "OR"s.
# * Output: 
# *      return 1 if changed the tree
# *      return 0 if there was NO change (no distributive rule to apply)
# * ========================================================================= */
#/* =========================================================================
#/* =========================================================================
# * Function: AndSort
# * Description: 
# *      Sort the list of nodes by increasing doc_count 
# *      Using some Neil Sharman code - pretty straight forward.
# *      Note: not-terms are sent to the end of the list
# * Input: 
# * Output: 
# * ========================================================================= */

# From managing gigabytes bool_optimiser.c
# - function: TF_Idempotent -> DONE


sub plan_for {
  my ($self, $index) = @_;

  # TODO: Order negatives before!
  # TODO: Remove duplicates!

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
  my $query_neg = $first->is_negative;

  # First operand is negative - remember this
  if ($query_neg) {

    # Set to positive
    $first->is_negative(0);
  };

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

  join $op, map {
    $_->type eq 'fieldGroup' ? '(' . $_->to_string . ')' : $_->to_string
  } @{$self->operands_in_order};
};

1;
