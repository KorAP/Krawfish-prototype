package Krawfish::Posting::Token;
use parent 'Krawfish::Posting';
use strict;
use warnings;

sub new {
  my $class = shift;
  bless [@_], $class;
}

# Current document
sub doc_id {
  return $_[0]->[0];
};


# Start of span
sub start {
  return $_[0]->[1];
};


# End of span
sub end {
  return $_[0]->[2] // $_[0]->start + 1
};


# Payloads
sub payload {
  return $_[0]->[3] //= Krawfish::Posting::Payload->new;
};


1;
