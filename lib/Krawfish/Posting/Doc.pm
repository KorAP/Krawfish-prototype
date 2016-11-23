package Krawfish::Posting::Doc;
use strict;
use warnings;

sub new {
  my $class = shift;
  my $id = shift;
  bless \$id, $class;
}

# Current document
sub doc_id {
  return ${$_[0]};
};

sub to_string {
  '[' . ${$_[0]} . ']';
};

1;
