package Krawfish::Index::Store::V1::Fields;
use parent 'Krawfish::Index::Store::V1::Stream';
use Krawfish::Index::Store::V1::Util qw/enc_string dec_string/;
use Krawfish::Log;
use strict;
use warnings;

# TODO:
#   field names should have term_ids
#   all values should be stored in a sequential order
#   augmented by a skip list.
#
#   [i:doc_id][i:doc_field_length]([i:field_id][i:value_length][str:value])*
#
#   The fields are stored in ascending field_id order,
#   so its fast to find the correct value.
#   The first bit of the field length may indicate,
#   if the field is a string or a numerical value.
#
#   This may also have a next() and skip_doc() API
#   to move to the expected document in a sequential way,
#   which may be the case for Aggregate::Values. (Although,
#   this may be better to be stored in a different mechanism.)
#   In that case, a pointer mechanism is required.
#   Another good use-case is the fast collection of text siglen
#   for the virtualcorpus->textsiglen-vector method.

# Tie to a file
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


sub get_fields {
  my $self = shift;
  my $doc_id = shift;
  my $current = $self->skip_doc($doc_id);
};

1;
