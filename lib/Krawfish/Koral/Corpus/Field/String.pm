package Krawfish::Koral::Corpus::Field::String;
use Role::Tiny::With;
use strict;
use warnings;

with 'Krawfish::Koral::Corpus::Field';
with 'Krawfish::Koral::Corpus';

use constant DEBUG => 0;


sub new {
  my $class = shift;
  bless {
    key => shift
  }, $class;
};


sub key_type {
  'string';
};

1;
