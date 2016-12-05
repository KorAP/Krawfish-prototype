package Krawfish::Index::Stream;
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
    stream => '',    # May contain multiple elements
    finger => [],    # Finger registry to know, when
                     #   the bitstream can be closed
    start => shift,  # File offset of the bitstream
    length => shift, # Length of the segment in the file
    delta => [],     # Buffer for delta values
    freq => 0
  }, $class;
};

# Override
# This will describe the compression scheme
sub add;


# Override
# This will describe the compression scheme
sub get;


sub freq {
  $_[0]->{freq};
};


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
  $self->{stream} .= join '', @_;
};


# Set bytes at a certain byte offset in the stream
# This is necessary to augment the stream with skip entrie
sub set_bytes {
  my ($self, $offset, $length) = @_;
  ...
};


sub add_vint {
  my $self = shift;
  $self->add_bytes(encode_vint(@_));
}


sub add_simple_16 {
  my $self = shift;
  $self->add_bytes(encode_simple_16(@_));
};


# TODO: Ignore skip values!
sub get_vint {
  my ($self, $offset) = @_;
  return ($offset + 4, decode_vint(substr($self->{stream}, $offset, 4)));
};


# TODO: Ignore skip values!
sub get_simple_16 {
  my ($self, $offset) = @_;
  my $stream = $self->{stream};
  pos($stream) = $offset;
  if ($stream =~ /\G\[(?:[^\]]+?)\]/) {
    return ($offset + length($&), decode_simple_16($&));
  };
  return;
};


sub stream {
  $_[0]->{stream};
};

########################
# Conversion functions #
########################

# Encode variable integer
sub encode_vint {
  pack 'L', $_[0];
};


# Decode variable integer
sub decode_vint {
  unpack 'L', $_[0];
};


# Encode simple 16
sub encode_simple_16 {
  '[' . join(':', @_) . ']';
};


# Decode simple 16
sub decode_simple_16 {
  my $string = shift;
  if ($string =~ m/^\[([\d:]+?)\]$/) {
    return split(':', $1);
  };
  return ();
};


1;


__END__
