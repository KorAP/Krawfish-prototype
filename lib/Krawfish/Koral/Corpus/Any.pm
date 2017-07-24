package Krawfish::Koral::Corpus::Any;
use parent 'Krawfish::Koral::Corpus';
use Krawfish::Corpus::Any;
use strict;
use warnings;

# This matches all live documents!

sub new {
  my $class = shift;
  bless {
    any => 1
  }, $class;
};

sub is_any {
  1;
};

sub is_nothing {
  0;
};

sub type {
  'any';
};

sub is_leaf {
  1;
};

sub to_string {
  '[1]';
};

sub operands {
  return;
};

sub optimize {
  shift;
  return Krawfish::Corpus::Any->new(shift());
};


sub to_koral_fragment {
  return {
    '@type' => 'koral:field'
  };
};

1;
