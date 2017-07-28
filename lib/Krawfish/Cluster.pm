package Krawfish::Cluster;
use strict;
use warnings;

# Krawfish::Cluster queries to multiple nodes
# and takes care of failures in responses

sub new {
  my $class = shift;
  bless {
    nodes => []
  }, $class;
};

1;
