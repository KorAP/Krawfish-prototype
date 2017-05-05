package Krawfish::Index::Store::V1::ForwardPointer;
use strict;
use warnings;

# TODO:
#   For use in the cooccurrence-analysis,
#   this needs fast access to documents AND positions.
#   It needs next() and previous() methods.

sub new {
  my $class = shift;
  bless {
    offset => 0,
    index => shift,
    current => undef
  }, $class;
};

sub current {
  return $_[0]->{current};
};

sub get {
  my ($self, $offset) = @_;
  if (my $subtoken = $self->{buffer}->get($offset)) {
    $self->{offset} = $offset;
    return $subtoken;
  };
  $self->{offset} = 0;
  return;
};


sub next {}

sub previous {};

1;
