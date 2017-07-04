package Krawfish::Controller::VirtualCorpus;
use Mojo::Base 'Mojolicious::Controller';

sub ids {
  my $c = shift;

  # TODO:
  #   Simply to a search of the virtual corpus
  #   with a field collector for textSigle
};


# Post a VC that will be stored as a static file per segment
sub static {
  my $c = shift;

  # TODO:
  #   - Normalize the query before sending to the nodes
  #   - When adding a new static virtual corpus, it should return
  #     the number of documents added, so it is searched at least once.
};

1;
