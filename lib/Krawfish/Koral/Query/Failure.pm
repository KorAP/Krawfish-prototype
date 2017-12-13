package Krawfish::Koral::Query::Failure;
use Role::Tiny::With;
use strict;
use warnings;

with 'Krawfish::Koral::Query';

sub new {
  my $class = shift;
  bless {
    raw => shift
  }, $class;
};

sub type {
  'failure';
};

sub is_leaf {
  1;
};

sub to_string {
  '!!!';
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
  return;
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
  return shift->{raw}
};

sub from_koral {
  my $self = shift;
  return $self->new(shift);
};



1;
