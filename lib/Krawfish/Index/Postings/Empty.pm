package Krawfish::Index::Postings::Empty;
use parent 'Krawfish::Index::PostingPointer';
use strict;
use warnings;


# Represent an empty posting list


# Constructor
sub new {
  my $class = shift;
  my $term_id = shift;
  bless \$term_id, $class;
};


# Get frequency of postings in list
sub freq {
  0;
};


# Get associated term id
sub term_id {
  ${$_[0]};
};


# Stringification
sub to_string {
  '#' . $_[0]->term_id;
};


# Move to posting at a certain position
sub at {
  return;
};


# Lift a pointer into the empty list
sub pointer {
  warn q!You can't point into an empty list!;
  return;
};


1;
