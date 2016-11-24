package Krawfish;
use Krawfish::Koral;
use Mojo::Base 'Mojolicious';

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

  $r->post('/search')->to('Index#search');
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
