package Krawfish::Koral::Corpus::Field::Text;
use strict;
use warnings;
use Role::Tiny::With;

with 'Krawfish::Koral::Corpus::Field';
with 'Krawfish::Koral::Corpus';

sub key_type {
  'text';
};


# Contains the value in multi-token field
sub contains {
  my $self = shift;
  $self->{match} = 'contains';
  $self->value(shift) or return;
  return $self;
};


# Does not contain the value in multi-token field
sub excludes {
  my $self = shift;
  $self->{match} = 'excludes';
  $self->value(shift) or return;
  return $self;
};

1;
