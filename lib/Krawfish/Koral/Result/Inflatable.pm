package Krawfish::Koral::Result::Inflatable;
use strict;
use warnings;
use Role::Tiny;
requires qw/inflate
            to_string
            to_koral_fragment/;

# TODO:
#   This is now double with Krawfish::Koral::Query!
use constant {
  CONTEXT => 'http://korap.ids-mannheim.de/ns/koral/0.6/context.jsonld'
};


# Wrap the fragment in context
sub to_koral_query {
  my $self = shift;
  my $koral = $self->to_koral_fragment;
  $koral->{'@context'} = CONTEXT;
  return $koral;
};

1;
