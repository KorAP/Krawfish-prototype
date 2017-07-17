package Krawfish::Koral::Query::Nothing;
use parent 'Krawfish::Koral::Query';
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

sub normalize {
  $_[0];
};

sub optimize {
  $_[0];
};

sub remove_classes {
  $_[0];
};

1;
