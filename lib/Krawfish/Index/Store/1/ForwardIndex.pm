package Krawfish::Index::Store::V1::ForwardIndex;
use Krawfish::Index::Store::Util qw/enc_string
                                    dec_string
                                    enc_varint
                                    dec_varint/;
use strict;
use warnings;
use Data::BitStream;

# TODO:
#   The store should be versioned!
#
# TODO:
#   This should probably be renamed to ForwardStream,
#   while the index needs to contain an index pointing to the
#   offsets for the documents in question!
#
# TODO:
#   This should store all document data using
#   term-IDs (where possible).
#   Structure like
#   [length][subtoken-surface-token-ID][foundry-layer-ID][term] ...
#   [length][plain-text]
#   [length][subtoken-surface-token-ID][foundry-layer-ID][term] ...
#
#   The plain text contains blanks, commata, etc.
#   The subtokens point to byte offsets in the highly compressed forward index.
#


use constant {
  SUBTOKEN_MARKER    => 0b0000_0000,
  PLAIN_TOKEN_MARKER => 0b1111_0000,
  PLAIN_MARKER       => 0b1111_1111,
  WS_SCHEME          => 1 # Short string compression scheme optimized for whitespace
};

sub new {
  my $class = shift;
  my $short_string_compression_scheme = shift;
  bless {
    buffer => '', # Contains subtokens
    plain_tail  => '', # Contains plain strings
    plain_pos => 0,
    stream => '',
    compression_scheme => $short_string_compression_scheme
  }
  bless \$stream, $class;
};

sub pos;

# Add term by id
sub add_term_id {
  my ($foundry_id, $layer_id, $term_id) = @_;
  # The term_id is a surface term,
  # meaning this adds a new subtoken marker
  if ($foundry_layer_id == 0) {
    $self->_flush;
    $self->{buffer} .= enc_varint($term_id);
  }
  else {
    $self->{buffer} .= $foundry_id . $layer_id;
    $self->{buffer} .= enc_varint($term_id);
  }
};


# Flush the buffer
sub _flush {
  my $self = shift;

  # Calculate the subtoken length
  # TODO: Store in 2 bytes
  my $length = length(
    $self->{buffer} . $self->{plain_tail}
  );

  # Add subtoken to stream
  $self->{stream} .=
    SUBTOKEN_MARKER .
    $length .
    $self->{buffer} .
    PLAIN_MARKER .
    $self->{plain_tail} .
    $length;

  # TODO: For next() add PLAIN_MARKER and 2x length
  # TODO: For previous() add SUBTOKEN_MARKER, PLAIN_MARKER and 1x length
  $self->{buffer} = '';
  $self->{plain_tail} = '';
  $self->{plain_pos} = 0;
};

# Add an annotation
sub add_term {
  my ($foundry_id, $layer_id, $term) = @_;

  # The term_id is a surface term,
  # meaning this adds a new subtoken marker
  if ($foundry_layer_id == 0) {
    $self->_flush;
    $self->{buffer} .= PLAIN_MARKER . enc_varint($self->{plain_pos}++);
    $self->{plain_tail}  .= PLAIN_MARKER . enc_string(
      $term,
      $self->{compression_scheme}
    );
  }
  else {
    $self->{buffer} .= $foundry_id . $layer_id;
    $self->{buffer} .= PLAIN_MARKER . enc_varint($self->{plain_pos}++);
    $self->{plain_tail}  .= PLAIN_MARKER . enc_string(
      $term,
      $self->{compression_scheme}
    );
  }
};

# TODO: May return a subtoken object
sub get {
  my ($self, $offset) = @_;

  # TODO: Check for SUBTOKEN_MARKER
  # read length
  my $subtoken_length = substr($self->{buffer}, $offset, 1, 3);
  ...
};

# Add plain string
# for example punctuation, whitespace etc.
sub add_plain {
  my ($self, $string) = @_;
  $self->_flush;
  $self->{stream} .= PLAIN_TOKEN_MARKER . enc_string(
    $string,
    WS_SCHEME
  );
};


1;
