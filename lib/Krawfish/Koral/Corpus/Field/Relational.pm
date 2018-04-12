package Krawfish::Koral::Corpus::Field::Relational;
use strict;
use warnings;
use Krawfish::Log;
use Role::Tiny;

sub gt {
  my $self = shift;
  $self->{match} = 'gt';
  $self->value(shift) or return;
  return $self;
};

sub lt {
  my $self = shift;
  $self->{match} = 'lt';
  $self->value(shift) or return;
  return $self;
};


sub geq {
  my $self = shift;
  return $self->gt(shift)->is_inclusive(1);
};


sub leq {
  my $self = shift;
  return $self->lt(shift)->is_inclusive(1);
};


# TODO: Support existence
sub match {
  my $self = shift;
  if (@_) {
    $self->{match} = shift;
    return $self;
  };
  return $self->{match};
};

# Return long match op
sub match_long {
  my $self = shift;
  if ($self->is_inclusive) {
    return 'geq' if $self->match eq 'gt';
    return 'leq' if $self->match eq 'lt';
  }
  return $self->match;
};


# Overwrite inclusive in Field
sub is_inclusive {
  my $self = shift;
  if (@_) {
    $self->{inclusive} = shift;
    return $self;
  };
  return $self->{inclusive} // 0;
};


sub is_relational {
  my $self = shift;
  return 1 if ($self->{match} eq 'gt' || $self->{match} eq 'lt');
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
  elsif ($op eq 'lt' || $op eq 'gt') {
    warn 'Relational operations not yet supported';
  }
  else {
    warn 'Unknown operation';
  };

  return $self;
};


1;
