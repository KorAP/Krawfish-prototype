package Krawfish::Index::Forward;
use Krawfish::Index::Forward::Stream;
use Krawfish::Index::Forward::Doc;
# use Krawfish::Index::Store::V1::ForwardIndex;
use warnings;
use strict;

# TODO:
#   This API needs to be backed up by a store version.

# API:
# ->next_doc
# ->to_doc($doc_id)
# ->skip_pos($pos)
# ->next_subtoken (fails, when the document ends)
# ->prev_subtoken
#
# ->doc_id                # The current doc_id
# ->pos                   # The current subtoken position
#
# ->current               # The current subtoken object
#   ->preceding_data      # The whitespace data before the subtoken
#   ->subterm_id          # The current subterm identifier
#   ->annotations         # Get all annotations as terms
#   ->annotations(foundry_id)
#   ->annotations(foundry_id, layer_id)
#
# ->fields                # All fields as terms
# ->fields(field_key_id*) # All fields with the key_ids


sub new {
  my $class = shift;

  bless {
    docs => [],
    last_doc_id => 0
  }, $class;
};


# Get last document identifier aka max_doc_id
sub last_doc_id {
  $_[0]->{last_doc_id};
};


# Accept a Krawfish::Koral::Document object
sub add {
  my ($self, $doc) = @_;
  my $doc_id = $self->{last_doc_id}++;

  # This should
  $self->{docs}->[$self->last_doc_id] = $self->to_forward_index($doc);

  return $doc_id;
};


# Get a specific forward indexed document by doc_id
sub get {
  my ($self, $doc_id) = @_;

  if ($doc_id <= $self->last_doc_id) {
    return $self->{docs}->[$doc_id];
  };

  return;
};


# Add document to forward index
sub to_forward_index {
  my ($self, $doc) = @_;

  # Build a structure
  return Krawfish::Index::Forward::Doc->new($doc);
  # Krawfish::Index::Store::V1::ForwardIndex->new;
};


1;
