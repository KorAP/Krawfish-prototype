package Krawfish::Query::Util::Bits;
use parent 'Exporter';
use bytes;
use strict;
use warnings;

our @EXPORT;

@EXPORT = qw/bitstring/;

# Return the bit string for 2 bytes
sub bitstring ($) {
  return unpack "b16", pack "s", shift;
};

1;
