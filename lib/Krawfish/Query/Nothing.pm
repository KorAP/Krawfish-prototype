package Krawfish::Query::Nothing;
use parent 'Krawfish::Query';
use strict;
use warnings;

# This is a query that returns nothing
sub new {
  my $class = shift;
  my $var;
  bless \$var, $class;
};

sub current {
  return;
};

sub next {
  return;
};

sub skip_doc {
  return;
};

sub max_freq {
  0
};

sub to_string {
  '[0]';
};

1;
