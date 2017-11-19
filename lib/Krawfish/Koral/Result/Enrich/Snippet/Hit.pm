package Krawfish::Koral::Result::Enrich::Snippet::Hit;
use strict;
use warnings;
use Role::Tiny::With;
use Krawfish::Log;

use constant DEBUG => 0;

with 'Krawfish::Koral::Result::Enrich::Snippet::Markup';

# Stringify to brackets
sub to_brackets {
  my $self = shift;
  return $self->is_opening ? '[' : ']';
};


1;
