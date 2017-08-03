package Krawfish::Koral::Meta::Type::KeyID;
use strict;
use warnings;

sub new {
  my ($class, $term_id) = @_;
  bless \$term_id, $class;
};

sub to_string {
  '#' . ${$_[0]};
};

1;
