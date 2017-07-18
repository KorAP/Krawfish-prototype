package Krawfish::Index::Store::V1::Util;
use parent 'Exporter';
use strict;
use warnings;

our @EXPORT_OK = qw/enc_varint
                    dec_varint
                    enc_string
                    dec_string/;

# This is not allowed to contain the markers of
# Krawfish::Index::Store::ForwardIndex
#
# See, e.g.
#   https://github.com/antirez/smaz
#   https://en.wikipedia.org/wiki/Standard_Compression_Scheme_for_Unicode
#   https://tools.ietf.org/html/rfc1978
#   http://ed-von-schleck.github.io/shoco/
#
# The second parameter is the compression scheme, that may vary based on the language,
# or the data type (e.g. plain data)
#
# See https://en.wikipedia.org/wiki/Universal_code_(data_compression)
# for other encodings.
#
# A simple nice compact integer packaging is LSIC: http://ticki.github.io/blog/how-lz4-works/

sub enc_string ($$) {
  warn 'Short string encoding not implemented yet';
  return $_[0];
};

sub dec_string ($$) {
  warn 'Short string encoding not implemented yet';
  return $_[0];
};

# See e.g. https://github.com/pascaldekloe/flit
sub enc_varint ($) {
  warn 'varint encoding not implemented yet';
  return $_[0];
};

sub dec_varint ($) {
  warn 'varint encoding not implemented yet';
  return $_[0];
};

1;
