package Krawfish::Koral::Query;
use strict;
use warnings;

use constant CONTEXT => 'http://korap.ids-mannheim.de/ns/koral/0.6/context.jsonld';

sub to_koral_query {
  my $self = shift;
  return {
    '@context' => CONTEXT,
    'query' => $self->to_koral_query_fragment
  }
};

1;
