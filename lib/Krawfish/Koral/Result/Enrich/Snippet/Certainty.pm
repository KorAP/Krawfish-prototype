package Krawfish::Koral::Result::Enrich::Snippet::Certainty;
use strict;
use warnings;
use Role::Tiny;

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
