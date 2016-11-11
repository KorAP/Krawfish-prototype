package Krawfish::Koral::Query::TermGroup;
use Krawfish::Koral::Query::Term;
use parent 'Krawfish::Koral::Query';
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
  @{$_[0]->{operands}};
};

sub to_string {
  my $self = shift;
  my $op = $self->operation eq 'and' ? '&' : '|';
  join $op, map {
    $_->type eq 'termGroup' ? '(' . $_->to_string . ')' : $_->to_string
  } $self->operands;
};

1;
