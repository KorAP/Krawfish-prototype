package Krawfish;
use Krawfish::Koral;
use Mojo::Base 'Mojolicious';

our $VERSION = '0.0.1';

# This method will run once at server start
sub startup {
  my $self = shift;

  $self->helper(
    koral => sub {
      shift;
      Krawfish::Koral->new(@_);
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
  $r->post('/statistics')->to('Corpus#statistics');

  $r->get('/corpus/:csigle/:dsigle/:tsigle')->to('Corpus#match');

  $r->put('/corpus/:uid')->to('Index#add');
  $r->put('/corpus/:csigle/:dsigle/:tsigle')->to('Index#add');

  $r->delete('/corpus/:uid')->to('Index#delete');
  $r->delete('/corpus/:csigle/:dsigle/:tsigle')->to('Index#delete');

  # TODO: Commit?
};

1;
