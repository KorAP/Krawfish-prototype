package Krawfish::Koral::Corpus::Nowhere;
use Role::Tiny::With;
use Krawfish::Query::Nowhere;
use strict;
use warnings;

with 'Krawfish::Koral::Corpus';

sub new {
  my $class = shift;
  bless {
    nowhere => 1
  }, $class;
};

sub type {
  'nowhere';
};

sub is_leaf {
  1;
};

sub is_relational {
  0;
};

sub to_string {
  '[0]';
};

sub operands {
  return;
};


sub is_nowhere {
  1;
};


sub identify {
  $_[0];
};

sub optimize {
  Krawfish::Query::Nowhere->new;
};

sub from_koral {
  ...
};

sub to_koral_fragment {
  ...
};

1;
