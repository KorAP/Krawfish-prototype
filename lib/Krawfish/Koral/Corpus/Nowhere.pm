package Krawfish::Koral::Corpus::Nowhere;
use parent 'Krawfish::Koral::Corpus';
use Krawfish::Query::Nowhere;
use strict;
use warnings;

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

1;
