package Krawfish::Index::Store::V1::ForwardPointer;
use strict;
use warnings;

# TODO:
#   For use in the cooccurrence-analysis,
#   this needs fast access to documents AND positions.
#   It needs next() and previous() methods.

# Constructor
sub new {
  my $class = shift;
  bless {
    offset => 0,
    index => shift,
    current => undef
  }, $class;
};


# Get current token
sub current {
  return $_[0]->{current};
};


# Get posting by offset
sub get {
  my ($self, $offset) = @_;
  if (my $subtoken = $self->{buffer}->get($offset)) {
    $self->{offset} = $offset;
    return $subtoken;
  };
  $self->{offset} = 0;
  return;
};


# Move to next token
sub next {
  ...
}


# Move to previous token
sub previous {
  ...
};


1;
