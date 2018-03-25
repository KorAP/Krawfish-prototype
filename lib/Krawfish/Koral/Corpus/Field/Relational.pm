package Krawfish::Koral::Corpus::Field::Relational;
use Role::Tiny;
use strict;
use warnings;

sub geq {
  my $self = shift;
  $self->{match} = 'geq';
  $self->value(shift) or return;
  return $self;
};


sub leq {
  my $self = shift;
  $self->{match} = 'leq';
  $self->value(shift) or return;
  return $self;
};

sub is_relational {
  my $self = shift;
  return 1 if $self->match eq 'geq' || $self->match eq 'leq';
  return 0;
};


1;
