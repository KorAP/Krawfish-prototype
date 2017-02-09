package Krawfish::Index::Store::Stream;
use strict;
use warnings;

# This works like every query, but accesses
# real storage

sub new {
  my $class = shift;
  my $self = bless {
    file => shift,
    start => shift,
    length => shift,

    # This uses a different encoding
    # for document streams, spans etc.
    # Based on that encoding, the next postings
    # and the skipping is treated.
    # Based on the encoding, the object is chosen.
    # Based on the encoding, the packet structure is chosen.
    encoding => shift
  };
};

sub _init {
  # Load first X bytes from file
};

sub skip_doc;
sub next;

1;
