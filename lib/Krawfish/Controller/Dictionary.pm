package Krawfish::Controller::Dictionary;
use Mojo::Base 'Mojolicious::Controller';
use Krawfish::Koral::Query::Term;

use strict;
use warnings;

# TODO:
#   While suggest will only return a limited number of results,
#   it's beneficial to support returning all results, e.g.
#   to request all possible values to a field - e.g. all annotations
#   (foundry/layer) in the index to synchronize this information with Kustvakt

# TODO:
#   There should be a similar mechanism available that respects VC

sub terms {
  my $c = shift;

  # Define either field or foundry/layer+termType
  my $field = $c->param('field') // '';
  my $foundry = $c->param('foundry');
  my $layer = $c->param('layer');
  my $term_type = $c->param('termType') // 'token';

  # Key is either the field name or the annotation tag
  my $key = $c->param('key');

  # Accept optional value
  my $value = $c->param('value');

  # Support either no further value, or a prefix, or a regex
  my $prefix = $c->param('prefix');
  my $regex = $c->param('regex');

  # Set optional value for count
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
