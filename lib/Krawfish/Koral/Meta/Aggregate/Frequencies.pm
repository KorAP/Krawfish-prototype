package Krawfish::Koral::Meta::Aggregate::Frequencies;
use strict;
use warnings;

sub new {
  my $class = shift;
  my $self = '';
  bless \$self, $class;
};

sub type {
  'freq'
};

sub identify {
  $_[0];
};

sub normalize {
  $_[0];
};

sub to_string {
  'freq';
};

1;
