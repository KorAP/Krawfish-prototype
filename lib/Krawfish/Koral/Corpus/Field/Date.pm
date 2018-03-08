package Krawfish::Koral::Corpus::Field::Date;
use Role::Tiny::With;
use strict;
use warnings;

with 'Krawfish::Koral::Corpus::Field';
with 'Krawfish::Koral::Corpus';

use constant DEBUG => 0;

# TODO: A date should probably have a different prefix

sub new {
  my $class = shift;
  bless {
    key => shift
  }, $class;
};


sub key_type {
  'date';
};

1;
