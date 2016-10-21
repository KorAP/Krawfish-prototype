package Krawfish::Span::Term;
use parent 'Krawfish::Span';
use strict;
use warnings;

sub new {
  my $class = shift;
  bless [@_], $class;
}

# Current document
sub doc {
  return $_[0]->[0];
};


# Start of span
sub start {
  return $_[0]->[1];
};


# End of span
sub end {
  return $_[0]->start + 1
};

1;
