package Krawfish::Query::Nothing;
use parent 'Krawfish::Koral::Query';
use strict;
use warnings;

# This is a query that returns nothing


sub current {
  return;
};

sub next {
  return;
};

sub skip_doc {
  return;
};

sub freq {
  0
};

sub to_string {
  '[0]';
};

1;
