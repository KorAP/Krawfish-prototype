package Krawfish::Posting::Doc;
use strict;
use warnings;

# Make identical with DocWithFlags!

sub new {
  my $class = shift;
  my $id = shift;
  bless \$id, $class;
}

# Current document
sub doc_id {
  return ${$_[0]};
};

sub flags {
};

sub to_string {
  '[' . ${$_[0]} . ']';
};

1;
