package Krawfish::Index::PostingPointer;
use parent 'Krawfish::Query';
use Krawfish::Log;
use Krawfish::Posting::Data;
use Krawfish::Posting;
use Scalar::Util qw/refaddr/;
use strict;
use warnings;

use constant {
  DEBUG => 0,
  DOC_ID => 0
};

# TODO: Implement skipping efficiently!!!
# TODO: Implement next_doc efficiently!!!
# TODO: Implement freq_in_doc efficiently!!!
# TODO: Add direct access to doc_id!

# TODO: Use Stream::Finger instead of PostingPointer

# Points to a position in a postings list

# TODO: Return different posting types
#       Using current

sub new {
  my $class = shift;
  bless {
    list => shift,
    pos => -1
  }, $class;
};

sub freq {
  $_[0]->{list}->freq;
};


# Get the term from the list
sub term {
  $_[0]->{list}->term;
};


sub term_id {
  $_[0]->{list}->term_id;
};


# Forward position
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


sub close {
  ...
};


#sub list {
#  return $_[0]->{list};
#};


# Skip to a certain document, return the current
# doc_id
sub skip_doc {
  my ($self, $doc_id) = @_;

  print_log('ppointer', refaddr($self) . ': TEMP SLOW Skip to chosen document') if DEBUG;

  while (!$self->current || $self->current->doc_id < $doc_id) {
    $self->next or return;
  };
  return $self->current->doc_id;
};


sub skip_pos {
  my ($self, $pos) = @_;
  print_log('ppointer', refaddr($self) . ': TEMP SLOW Skip to chosen position or after')
    if DEBUG;

  unless ($self->current) {
    $self->next or return;
  };

  my $current = $self->current;
  my $start_doc_id = $current->doc_id;

  while ($start_doc_id == $current->doc_id && $current->start <= $pos) {
    $self->next or return;
    $current = $self->current;
  };

  return $current->start;
};

1;
