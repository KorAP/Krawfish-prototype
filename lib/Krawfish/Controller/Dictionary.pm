package Krawfish::Controller::Corpus;
use Mojo::Base 'Mojolicious::Controller';
use Krawfish::Koral::Query::Term;

use strict;
use warnings;

sub suggest {
  my $c = shift;

  my $field = $c->param('field') // '';
  my $prefix = $c->param('prefix');
  my $term_type = $c->param('termType') // 'token';
  my $foundry = $c->param('foundry');
  my $layer = $c->param('layer');
  my $key = $c->param('key');
  my $value = $c->param('value');
  my $count = $c->param('count');


  # TODO: Probably use Krawfish::Util::Koral::Term
  my $term = Krawfish::Koral::Query::Term->new;
  $term->field($field);
  $term->prefix($prefix);
  $term->term_type($term_type);
  $term->foundry($foundry);
  $term->layer($layer);
  $term->key($key);
  $term->value($value);

  # Stringify as fragment
  my $term_escaped = quotemeta($term->to_string(1));

  # Return
  my @array = $c->krawfish->node->dictionary->terms(qr!^$term_escaped.+?!);

  return $c->render(json => [@array[0..$count]]);
};

1;
