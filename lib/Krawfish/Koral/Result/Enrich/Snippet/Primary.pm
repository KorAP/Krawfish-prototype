package Krawfish::Koral::Result::Enrich::Snippet::Primary;
use strict;
use warnings;
use Role::Tiny::With;

with 'Krawfish::Koral::Result::Enrich::Snippet::Markup';

sub to_brackets {
  return $_[0]->{data};
};

sub to_html {
  return $_[0]->{data};
};

sub to_specific_string {
  return 'primary;';
};


1;
