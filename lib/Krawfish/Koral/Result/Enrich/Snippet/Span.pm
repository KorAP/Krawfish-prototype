package Krawfish::Koral::Result::Enrich::Snippet::Span;
use strict;
use warnings;
use Role::Tiny;
use Krawfish::Log;

with 'Krawfish::Koral::Result::Enrich::Snippet::Markup';
with 'Krawfish::Koral::Result::Enrich::Snippet::TUI';
with 'Krawfish::Koral::Result::Enrich::Snippet::Certainty';

# Spans are used for token as well as span annotations,
# therefore even tokens can have a depth information

use constant DEBUG => 0;

# Depth
sub depth {
  my $self = shift;
  if (@_) {
    $self->{depth} = shift;
    return $self;
  };
  return $self->{depth};
};

1;
