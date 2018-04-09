package Krawfish::Koral::Corpus::Field::Relational;
use Role::Tiny;
use strict;
use warnings;

# TODO:
#   Only support lt and gt and
#   have a separate "inclusive" flag
#   for ge and le!
#   This would help dealing with
#   FieldRanges!

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


# Toggle negativity
sub toggle_negative {
  my $self = shift;
  my $op = $self->match;

  # Reverse operation
  if ($op eq 'eq') {
    $self->{match} = 'ne';
    $self->is_negative(1);
  }
  elsif ($op eq 'ne') {
    $self->{match} = 'eq';
    $self->is_negative(0);
  }
  elsif ($op eq 'contains') {
    $self->{match} = 'excludes';
    $self->is_negative(1);
  }
  elsif ($op eq 'excludes') {
    $self->{match} = 'contains';
    $self->is_negative(0);
  }
  elsif ($op eq 'leq' || $op eq 'geq') {
    warn 'Relational operations not yet supported';
  }
  else {
    warn 'Unknown operation';
  };

  return $self;
};


1;
