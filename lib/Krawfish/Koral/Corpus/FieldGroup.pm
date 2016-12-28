package Krawfish::Koral::Corpus::FieldGroup;
use parent 'Krawfish::Koral::Corpus';
use Krawfish::Log;
use Krawfish::Corpus::Or;
use Krawfish::Corpus::And;
use Krawfish::Corpus::Without;
use Krawfish::Corpus::Negation;
use Krawfish::Corpus::All;
use strict;
use warnings;

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
  $_[0]->{operation};
};

sub operands {
  $_[0]->{operands}
};

sub is_negative {
  my $self = shift;
  foreach (@{$self->operands}) {
    return unless $_->is_negative;
  };
  return 1;
};

sub plan_for {
  my ($self, $index) = @_;

  my $ops = $self->operands;

  # TODO: Order negatives before!
  # TODO: Remove duplicates!

  my $i = 0;

  # Check the frequency of all operands
  # Start with a query != null
  my $first = $ops->[$i];
  my $query_neg = $first->is_negative;
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

    # Filter out all terms that do not occur
    for (; $i < @$ops; $i++) {
      my $option = $ops->[$i]->plan_for($index);
      if ($option->freq != 0) {
        $query = Krawfish::Corpus::Or->new(
          $query,
          $option
        )
      };
    };
  }

  elsif ($self->operation eq 'and') {

    print_log('kq_fgroup', 'Prepare and-group') if DEBUG;

    my $option_neg = 0;

    # Filter out all terms that do not occur
    for (; $i < @$ops; $i++) {

      my $next = $ops->[$i];
      $option_neg = $next->is_negative;
      if ($option_neg) {
        # Set to positive
        $next->is_negative(0);
      };
      my $option = $next->plan_for($index);

      # Do not add useless options
      # TODO: What if it is part of a negation???
      next if $option->freq == 0;

      # Both operands are negative
      if ($query_neg || $option_neg) {


        if ($query_neg && $option_neg) {
          $query = Krawfish::Corpus::Or->new(
            $query,
            $option
          );
          $query_neg = 1;
        }

        # Option is negative
        elsif ($option_neg) {
          $query = Krawfish::Corpus::Without->new(
            $query,
            $option
          );
          $query_neg = 0;
        }

        # Base query is negative - reorder query
        else {
          $query = Krawfish::Corpus::Without->new(
            $option,
            $query
          );
          $query_neg = 0;
        };
      }

      # No negative query
      else {
        $query = Krawfish::Corpus::And->new(
          $query,
          $option
        );
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
  } @{$self->operands};
};

1;
