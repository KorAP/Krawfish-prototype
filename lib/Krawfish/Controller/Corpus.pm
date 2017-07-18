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


# Get information per text
sub text {
  my $self = shift;

  my $koral = Krawfish::Koral->new;
  my $meta = $koral->meta_builder;

  my $v = $c->validation;
  $v->optional('fields');


  # Get the text sigle from the stash
  my $corpus_id = $c->stash('corpus_id');
  my $doc_id    = $c->stash('doc_id');
  my $text_id   = $c->stash('text_id');

  my $sigle = join('/', $corpus_id, $doc_id, $text_id);

  # Set corpus
  $koral->corpus(
    $koral->corpus_builder->string('text_sigle' => $text_sigle)
  );

  # Get the field information
  my $fields = b($v->param('fields'))->split(',')->uniq->to_array;
  if ($fields->[0]) {
    $meta->fields($fields);
  };

  # Limit to a single match
  $meta->limit(1);

  # Set meta
  $koral->meta($meta);

  # Get segment index
  my $index = $c->index->segment;

  # Prepare query on index
  $c->render(json => $koral->to_result($index));
};


# Get a virtual corpus and a list of terms -
# returns the frequency per term in the virtual corpus
# (potentially per corpus class)
sub frequencies {
  my $c = shift;

  # This is a very important endpoint as it is used for
  # statistics on a virtual corpus (number of sentences in a corpus)
  # as well as for co-occurrence search.
  #
  # Beside terms, this also support the frequency count of tokens
  # for certain foundries.
  #
  # This uses Result::Aggregate::TermFreq and
  # Result::Aggregate::TokenFreq
};

1;
