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


# Get current posting
sub current {
  return;
};


# Clone query
sub clone {
  __PACKAGE__->new;
};


# Move to next posting
sub next {
  return;
};


# Skip to target document (invalid)
sub skip_doc {
  return;
};


# Get maximum frequency
sub max_freq {
  0
};


# Stringification
sub to_string {
  '[0]';
};


# Filter query by VC (invalid)
sub filter_by {
  return;
};

1;
