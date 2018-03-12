package Krawfish::Koral::Corpus::Anywhere;
use Role::Tiny::With;
use Krawfish::Corpus::Anywhere;
use strict;
use warnings;

with 'Krawfish::Koral::Corpus';

# This matches all live documents!

sub new {
  my $class = shift;
  bless {
    anywhere => 1
  }, $class;
};

sub is_anywhere {
  1;
};

sub is_nowhere {
  0;
};

sub type {
  'anywhere';
};

sub is_leaf {
  1;
};

sub is_relational {
  0;
};

sub to_string {
  '[1]';
};

sub operands {
  return;
};

sub optimize {
  shift;
  return Krawfish::Corpus::Anywhere->new(shift());
};


sub to_koral_fragment {
  return {
    '@type' => 'koral:field'
  };
};


sub from_koral {
  ...
};

1;
