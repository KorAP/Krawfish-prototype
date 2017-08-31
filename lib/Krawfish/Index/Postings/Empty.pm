package Krawfish::Index::Postings::Empty;
use strict;
use warnings;

# This list is empty

sub new {
  my $class = shift;
  my $term_id = shift;
  bless \$term_id, $class;
};


sub freq {
  0;
};

sub term_id {
  ${$_[0]};
};

# Stringification
sub to_string {
  '#' . $_[0]->term_id;
};

sub at {
  return;
};

sub pointer {
  warn q!You can't point into an empty list!;
  return;
};

1;
