package Krawfish::Koral::Query::Nowhere;
use Role::Tiny::With;
use Krawfish::Query::Nowhere;
use strict;
use warnings;

with 'Krawfish::Koral::Query';

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

sub normalize {
  $_[0];
};

sub finalize {
  $_[0];
};

sub identify {
  $_[0];
};

sub optimize {
  Krawfish::Query::Nowhere->new;
};

sub operand {
  undef;
};

sub operands {
  [];
};

sub remove_classes {
  $_[0];
};

sub min_span {
  -1;
};

sub max_span {
  -1;
};

sub to_koral_fragment {
  ...
};

1;
