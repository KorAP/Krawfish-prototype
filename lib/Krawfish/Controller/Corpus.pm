package Krawfish::Controller::Corpus;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::ByteStream 'b';

use Krawfish::Koral::Corpus::Builder;
use Krawfish::Koral::Meta;

use strict;
use warnings;

sub corpus {
  my $c = shift;
  my $v = $c->validation;
  $v->optional('fields');
  $v->optional('count');
  $v->optional('page');
  $v->optional('sortBy');

  my $corpus_id = $c->stash('corpus_id');

  my $koral = Krawfish::Koral->new;

  # set corpus
  $koral->corpus(
    $koral->corpus_builder->string('corpus_id' => $corpus_id)
  );

  my $meta = $koral->meta_builder;
  $meta->items_per_page($v->param('count'));
  $meta->start_index($v->param('page')); # TODO!
  #  if ($v->param('sortBy')) {
  #    $meta->field_sort()
  #  };
  # etc.

  my $fields = b($v->param('fields'))->split(',')->uniq->to_array;
  if ($fields->[0]) {
    $meta->fields($fields);
  };

  # Set meta
  $koral->meta($meta);

  # Get segment index
  my $index = $c->index->segment;

  # Prepare query on index
  $c->render(json => $koral->to_result($index));
};

1;
