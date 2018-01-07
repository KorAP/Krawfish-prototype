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

sub type {
  'hit';
};

sub to_specific_string {
  return $_[0]->type;
};

sub number {
  0;
};

sub to_html {
  my $self = shift;
  return $self->is_opening ? '<span class="match"><mark>' : '</mark></span>';
};

1;
