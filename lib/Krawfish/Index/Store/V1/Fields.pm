package Krawfish::Index::Store::V1::Fields;
use parent 'Krawfish::Index::Store::V1::Stream';
use Krawfish::Index::Store::V1::Util qw/enc_string dec_string/;
use Krawfish::Log;
use strict;
use warnings;

# All keys are stored in sequential order augmented by a skip list.
# The index structure is
#
#   (
#     [skip-data:skip-data]?
#     [doc_id:int]
#     [doc_length:varint]
#     (
#       [field_key_id:delta-varint]
#       [type:b]
#       (
#         [term_id:varint] |
#         [value-length:varint][value:bytes] |  # As a p-string
#         [value:varint]
#       )
#     )*
#   )*
#
# The fields are stored in ascending field_id order,
# so its fast to find the correct value.
# The type byte can have multiple values:
#     0: It's a string
#     1: It's an integer
#     2: It's a stored string value
#
# Stored string values are short-word-compressed.
#
# Per key a field value can occur multiple times.

# TODO:
#   This also requires a next_doc() and skip_doc() API
#   to move to the expected document in a sequential way,
#   which may be the case for Aggregate::Values. (Although,
#   this may be better to be stored in a different mechanism.)
#   In that case, a pointer mechanism is required.
#   Another good use-case is the fast collection of text siglen
#   for the virtualcorpus->textsiglen-vector method.


# Constructor tied to a file
sub new {
  my ($class, $file, $dict) = @_;
  bless {
    file => $file,
    dictionary => $dict
  }, $class;
};


# Store information on a document
# The doc_id needs to be greater than the last doc_id
sub store {
  my $self = shift;
  my $doc_id = shift;

  # Expected structure is:
  # field_id => str
  my %raw_fields = @_;
  my %fields = ();

  # Translate field names to term_ids
  foreach (keys %raw_fields) {
    $fields{$self->{dict}->term_id_by_term($_)} = $raw_fields{$_};
  };

  my $bytes = '';

  # Sort term_ids numerical
  foreach (sort keys %fields) {
    $bytes .= $_;
    my $value = enc_string $value;
    $bytes .= length($value);
    $bytes .= $value;
  };

  # Append byte to stream
  $self->_append($doc_id, $bytes);
};


# Get fields by doc
sub get_fields {
  my ($self, $target_doc_id) = @_;
  my $current = $self->skip_doc($target_doc_id);
};

1;
