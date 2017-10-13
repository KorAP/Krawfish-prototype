package Krawfish::Index::PostingPointer;
use parent 'Krawfish::Query';
use Krawfish::Log;
use Krawfish::Posting::Data;
use Krawfish::Posting;
use Scalar::Util qw/refaddr/;
use strict;
use warnings;

# Moving pointer in a posting list.

use constant {
  DEBUG => 0,
  DOC_ID => 0
};

# TODO:
#   Implement skipping efficiently!!!

# TODO:
#   Implement next_doc efficiently!!!

# TODO:
#   Implement freq_in_doc efficiently!!!

# TODO:
#   Add direct access to doc_id!

# TODO:
#   Use Stream::Finger instead of PostingPointer

# TODO:
#   Return different posting types using current


# Constructor
sub new {
  my $class = shift;
  bless {
    list => shift,
    pos => -1
  }, $class;
};


# Get frequency of the list
# (probably copy value when posting pointer is lifted)
sub freq {
  $_[0]->{list}->freq;
};


# Get the term id
# (probably copy value when posting pointer is lifted)
sub term_id {
  $_[0]->{list}->term_id;
};


# Move to next posting
sub next {
  my $self = shift;
  my $pos = $self->{pos}++;
  return ($pos + 1) < $self->freq ? 1 : 0;
};


# Get the frequency of the term in the document
# This is just a temporary implementation
sub freq_in_doc {
  my $self = shift;

  print_log('ppointer', refaddr($self) .
              ': TEMP SLOW Get the frequency of the term in the doc') if DEBUG;

  # This is the doc_id
  my $current_doc_id = $self->current->doc_id;
  my $pos = $self->{pos};
  my $freq = 0;
  my $all_freq = $self->freq;


  # Move to the start of the document
  while ($pos > 0 && ($self->{list}->at($pos-1)->[DOC_ID] == $current_doc_id)) {
    $pos--;
  };

  # Move to the end of the document
  while ($pos < $self->freq && ($self->{list}->at($pos++)->[DOC_ID] == $current_doc_id)) {
    $freq++;
  };

  # Return the frequency
  return $freq;
};


# Get the current position in the list
sub pos {
  return $_[0]->{pos};
};


# This does NOT return a posting, so it may be called differently
# This is called by different term types - so this could be named current_data
sub current {
  my $self = shift;

  my $data = $self->{list}->at($self->pos) or return;

  Krawfish::Posting::Data->new(
    $data
  );
};


# Potentially close pointer
sub close {
  ...
};


# Skip to a certain document,
# return the new doc_id
sub skip_doc {
  my ($self, $target_doc_id) = @_;

  # TODO:
  #   Return NOMORE in case there are no more postings.

  print_log('ppointer', refaddr($self) . ': TEMP SLOW Skip to chosen document') if DEBUG;

  while (!$self->current || $self->current->doc_id < $target_doc_id) {
    $self->next or return;
  };

  return $self->current->doc_id;
};


# Skip to a certain position in the list
sub skip_pos {
  my ($self, $target_pos) = @_;

  if (DEBUG) {
    print_log('ppointer', refaddr($self) . ': TEMP SLOW Skip to chosen position or after');
  };

  unless ($self->current) {
    $self->next or return;
  };

  my $current = $self->current;
  my $start_doc_id = $current->doc_id;

  while ($start_doc_id == $current->doc_id && $current->start <= $target_pos) {
    $self->next or return;
    $current = $self->current;
  };

  return $current->start;
};


1;
