package Krawfish;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
  my $self = shift;

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to(
    cb => sub {
      shift->render(text => 'Welcome!');
    });
}

1;
