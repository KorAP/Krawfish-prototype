package Krawfish::Koral::Query::TermGroup;
use parent 'Krawfish::Koral::Query';
use Krawfish::Koral::Query::Term;
use Krawfish::Query::Or;
use Krawfish::Query::Position;
use Scalar::Util qw/blessed/;
use strict;
use warnings;

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
sub plan_for {
  my $self = shift;
  my $index = shift;
  my $ops = $self->operands;
  my $query = $ops->[0]->plan_for($index);

  # Serialize for 'or' operation
  if ($self->operation eq 'or') {

    for (my $i = 1; $i < @$ops; $i++) {
      $query = Krawfish::Query::Or->new(
        $query,
        $ops->[$i]->plan_for($index)
      )
    };
  }

  # Serialize for 'and' operation
  else {

    # TODO: Order by frequency!
    for (my $i = 1; $i < @$ops; $i++) {
      $query = Krawfish::Query::Position->new(
        MATCHES,
        $query,
        $ops->[$i]->plan_for($index)
      )
    };
  };

  return $query;
};


sub to_string {
  my $self = shift;
  my $op = $self->operation eq 'and' ? '&' : '|';
  join $op, map {
    $_->type eq 'termGroup' ? '(' . $_->to_string . ')' : $_->to_string
  } @{$self->operands};
};

1;
