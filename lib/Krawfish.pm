package Krawfish;
use Krawfish::Koral;
use Mojo::Base 'Mojolicious';

our $VERSION = '0.0.2';

# This method will run once at server start
sub startup {
  my $self = shift;

  $self->helper(
    koral => sub {
      shift;
      Krawfish::Koral->new(@_);
    }
  );


  $self->helper(
    'krawfish.node.dictionary' => sub {
      ...
    }
  );

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to(
    cb => sub {
      my $c = shift;
      my $koral = $c->koral->message(680, "Server is up and running!");
      $c->render(json => $koral->to_koral_query);
    });


  # Search documents
  # This will return a list of matches,
  # that can be
  # - augmented with document field information
  # - sorted by
  #   - field values
  #   - alphabetic (by classes, defaults to class 0)
  #   - random
  # - limited
  # - accompanied with
  #   - field-facets
  #   - frequencies
  #   - length information
  #   - field value aggregated information
  $r->post('/search')->to('Index#search');

  # TODO:
  #   For offsets like "give me all results from page 5" it's beneficial
  #   to have a socket connection to all nodes, probably using protobuf
  #   or similar, that returns first only the sorting vector, before retrieving
  #   the snippet results.
  #   The same mechanism is probably also useful for sorting per node
  #   because it means that snippets are not important.
  # $r->post('/search')->to('Index#search_dynamic');

  # Group matches
  # This will return a list of matching groups,
  # that can be based on classes
  # - with surface forms
  # - with annotations
  # - with start/end characters of surface forms
  # - sorted by
  #   - frequency of group
  #   - document frequency of group
  #   - alphabetic (per classes)
  $r->post('/group')->to('Index#group');

  # TODO:
  #   Provide a streaming API (possibly accessible via socket)
  #   for matches (e.g. to rank or group them)
  #   For example: return a string with all surface terms in a match,
  #   possibly with context
  $r->post('/collect/:resultid')->to('Index#collect');

  # Statistics is irrelevant when there is /freq
  # $r->post('/statistics')->to('Corpus#statistics');

  # This is an API for co-occurrence processing.
  # It accepts a virtual corpus in the body
  # and a list of terms, that need term frequency information
  # This will be also used for virtual corpus statistics,
  # e.g. to get the number of sentences in a virtual corpus.
  $r->post('/freq')->to('Corpus#frequencies');

  $r->get('/corpus/:corpus_id/')->to('Corpus#corpus');
  $r->get('/corpus/:corpus_id/:doc_id')->to('Corpus#doc');
  $r->get('/corpus/:corpus_id/:doc_id/:text_id')->to('Corpus#text');
  $r->get('/corpus/:corpus_id/:doc_id/:text_id/:match')->to('Corpus#match');

  $r->put('/corpus/:uid')->to('Index#add');
  $r->put('/corpus/:corpus_id/:doc_id/:text_id')->to('Index#add');

  $r->delete('/corpus/:uid')->to('Index#delete');
  $r->delete('/corpus/:corpus_sigle/:doc_id/:text_id')->to('Index#delete');
  # TODO:
  #   Delete by search

  # Web sockets only make sense for the central node
  $r->get('/suggest')->to('Dictionary#suggest');

  # Send a Virtual corpus and return an id vector
  # This is necessary for archiving and migration.
  # It accepts a virtual corpus and returns a vector of
  # text siglen
  $r->post('/vc/ids')->to('VirtualCorpus#ids');
  $r->get('/vc/:vc_id/ids')->to('VirtualCorpus#ids');

  # Create a new static virtual corpus by receiving a
  # KoralQuery corpus query.
  $r->put('/vc/static/:id')->to('VirtualCorpus#static');

  # Delete a static virtual corpus
  $r->delete('/vc/static/:id')->to('VirtualCorpus#static_delete');

  # TODO:
  #   some routes for experimental endpoints
  my $experimental = $r->get('/experimental');
  $r->get('/distribution')->to('Distribution#dist');

  # TODO: Commit?
};

1;


__END__

Furter Requirements:
- For KorapSRU it is necessary to provide the sum of all foundries
  of a virtual corpus. This can be done by using a facet aggregation mechanism
  for multivalued fields.
