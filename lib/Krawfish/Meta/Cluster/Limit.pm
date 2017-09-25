package Krawfish::Meta::Cluster;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless {
    query => shift
  }, $class;
};

1;
