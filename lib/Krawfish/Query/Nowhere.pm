package Krawfish::Query::Nowhere;
use parent 'Krawfish::Query';
use strict;
use warnings;

# This is a query that returns nowhere
sub new {
  my $class = shift;
  my $var;
  bless \$var, $class;
};

sub current {
  return;
};

sub clone {
  __PACKAGE__->new;
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

sub filter_by {
  return;
};

1;
