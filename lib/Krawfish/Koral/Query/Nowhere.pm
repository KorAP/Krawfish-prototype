package Krawfish::Koral::Query::Nowhere;
use parent 'Krawfish::Koral::Query';
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

1;
