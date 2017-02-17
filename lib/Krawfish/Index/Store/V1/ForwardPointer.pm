package Krawfish::Index::Store::V1::ForwardPointer;
use strict;
use warnings;

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

1;
