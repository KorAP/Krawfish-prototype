package Krawfish::Posting::Doc;
use strict;
use warnings;

# Document based posting

# Constructor
sub new {
  my $class = shift;
  my $id = shift;
  bless \$id, $class;
}

# Current document
sub doc_id {
  return ${$_[0]};
};


# Get flags
sub flags {
};


# Stringification
sub to_string {
  '[' . ${$_[0]} . ']';
};


1;
