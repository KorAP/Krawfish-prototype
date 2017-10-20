package Krawfish::Posting::Doc;
use strict;
use warnings;

# Document based posting

# TODO:
#   This should be the base class
#   with flags!

# Constructor
sub new {
  my $class = shift;
  my $id = shift;
  bless \$id, $class;
};

sub flags {
  0;
};

# Current document
sub doc_id {
  return ${$_[0]};
};


# Stringification
sub to_string {
  '[' . ${$_[0]} . ']';
};


1;
