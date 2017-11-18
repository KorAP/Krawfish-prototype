package Krawfish::Koral::Result::Enrich::Snippet::Hit;
use strict;
use warnings;
use Role::Tiny;
use Krawfish::Log;

with 'Krawfish::Koral::Result::Enrich::Snippet::Markup';

use constant DEBUG => 0;


# Stringify to brackets
sub to_brackets {
  my $self = shift;
  return $self->is_opening ? '[' : ']';
};


1;
