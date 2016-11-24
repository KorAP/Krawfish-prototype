package Krawfish::Controller::Index;
use Mojo::Base 'Mojolicious::Controller';
use strict;
use warnings;

sub add {
  my $c = shift;
  my $kq = $c->koral->error(000, 'Index creation not yet implemented');
  $c->render(json => $kq);
};

1;
