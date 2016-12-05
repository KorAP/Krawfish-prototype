package Krawfish::Index::BitStream;
use strict;
use warnings;


# TODO:
#   Vint should be as simple as possible
# TODO:
#   BitStream should support multiple pointers,
#   And the stream should be closed, once no pointers
#   point to it any longer
# TODO:
#   BitStream may be loaded from a file and may
#   load further elements, once it exceeds the boundaries
#   of the current element

sub new {
  my $class = shift;
  bless {
    stream => [], # May contain multiple elements
    finger => [], # Finger registry to know, when
                  #   the bitstream can be closed
    start => 0,   # File offset of the bitstream
    length => 0   # Length of the segment in the file
  }, $class;
};

# Override
# This will describe the compression scheme
sub schema;

sub current {
  # Return the data at the current position
  # This will convert all values based
  # on schema
  ...
};

# Get the next item, based on the current schema
# This will ignore all skip entries
sub next {
  my ($self, $offset) = @_;
  ...
};

sub next_pos;

sub next_doc;


# Skip to or beyond a certain doc id and to or before a certain position
sub skip_to {
  my $self = shift;
  my ($offset, $doc_id, $pos) = @_;
  # The offset comes from the finger position in the byte stream
  ...
};

# Add bytes at the end of the stream
sub add_bytes {
  my $self = shift;
  ...
};


# Set bytes at a certain byte offset in the stream
# This is necessary to augment the stream with skip entrie
sub set_bytes {
  my ($self, $offset, $length) = @_;
  ...
};


########################
# Conversion functions #
########################

# Encode variable integer
sub enc_vint {
  ...
};


# Decode variable integer
sub dec_vint {
  ...
};

# Encode simple 16
sub enc_simple_16 {
  ...
};

# Decode simple 16
sub dec_simple_16 {
  ...
};

1;


__END__
