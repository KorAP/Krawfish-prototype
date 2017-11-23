package Krawfish::Index::Fields::Rank;
use strict;
use warnings;

sub {
  my $class = shift;
  bless {
    collocation => shift,
    list => []
  }, $class;
};

sub skip_to {
  my ($self, $rank) = @_;
  ...
};

sub max_rank {
  ...
};

sub collocation {
  $_[0]->{collocation};
};

1;
