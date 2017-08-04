package Krawfish::Koral::Meta::SortFilter;
use strict;
use warnings;

warn 'DEPRECATED';

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

sub identify {
  warn 'DEPRECATED';
  $_[0];
};

sub wrap {
  warn 'Should never be called!';
};


sub to_string {
  'sortFilter';
};

1;
