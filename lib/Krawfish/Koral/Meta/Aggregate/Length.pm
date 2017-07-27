package Krawfish::Koral::Meta::Aggregate::Length;
use strict;
use warnings;

sub new {
  my $class = shift;
  my $self = '';
  bless \$self, $class;
};

sub type {
  'length'
};


sub normalize {
  $_[0];
};

sub to_string {
  'length';
};

1;
