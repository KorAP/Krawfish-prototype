package Krawfish::Koral::Meta::SortFilter;
use strict;
use warnings;

sub new {
  my $class = shift;
  my $self = '';
  bless \$self, $class;
};

sub type {
  'sortFilter'
};

sub normalize {
  $_[0];
};

sub to_string {
  'sortFilter';
};

1;
