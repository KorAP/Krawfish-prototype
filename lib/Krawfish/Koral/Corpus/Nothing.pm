package Krawfish::Koral::Corpus::Nothing;
use parent 'Krawfish::Koral::Corpus';
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

1;
