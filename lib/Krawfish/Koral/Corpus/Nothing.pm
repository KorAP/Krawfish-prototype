package Krawfish::Koral::Corpus::Nothing;
use parent 'Krawfish::Koral::Corpus';
use Krawfish::Query::Nothing;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless {
    nothing => 1
  }, $class;
};

sub type {
  'nothing';
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


sub is_nothing {
  1;
};


sub identify {
  $_[0];
};

sub optimize {
  Krawfish::Query::Nothing->new;
};

1;
