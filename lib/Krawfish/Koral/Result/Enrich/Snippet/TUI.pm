package Krawfish::Koral::Result::Enrich::Snippet::TUI;
use strict;
use warnings;
use Role::Tiny;

# Token unique identifier
sub tui {
  my $self = shift;
  if (@_) {
    $self->{tui} = shift;
    return $self;
  };
  return $self->{tui};
};

1;
