package Krawfish::Koral::Result::Enrich::Snippet::Annotation;
use strict;
use warnings;
use Role::Tiny;

# TODO:
#   This role needs the term identifier
#   role!

sub foundry {};

sub layer {};

sub key {};

sub value {};

# Certainty of the annotation
sub certainty {
  my $self = shift;
  if (@_) {
    $self->{certainty} = shift;
    return $self;
  };
  return $self->{certainty};
};

1;
