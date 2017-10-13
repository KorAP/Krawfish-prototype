package Krawfish::Index::Forward;
use Krawfish::Index::Forward::Pointer;
use Krawfish::Index::Forward::Doc;
use Krawfish::Log;
use warnings;
use strict;

use constant DEBUG => 0;

# This represents a forward index of the data,
# accessible by document ID and subtoken offset.

# Merging the forward index is pretty simple, as it only
# needs to be indexed on the document level and then
# simply be appended.

# TODO:
#   This is great for retrieving pagebreaks, annotations, primary data,
#   perhaps help on regex ...
#   But can this help to expand the context of a match to a certain element context?
#   Probably by retrieving the data with a certain maximum offset (say left 100 subtokens, right 100 subtokens)
#   and first check for the expanding element start on the left, then move to the right.

# TODO:
#   In case the term IDs are retrieved for surface sorting,
#   it may be useful to not have much data in memory.
#   Look into K::I::Subtokens for use of $term_ids there. It may not be crucial though.

# TODO:
#   The forward index needs fast access to documents and positions,
#   to get term ids from contexts for use in the co-occurrence analysis.

# TODO:
#   This API needs to be backed up by a store version.
#   use Krawfish::Index::Store::V1::ForwardIndex;

# Constructor
sub new {
  my $class = shift;

  bless {
    docs => [],
    last_doc_id => -1
  }, $class;
};


# Get last document identifier aka max_doc_id
sub last_doc_id {
  $_[0]->{last_doc_id};
};


# Accepts a Krawfish::Koral::Document object
sub add {
  my ($self, $doc) = @_;
  my $doc_id = $self->{last_doc_id}++;

  # TODO:
  #   use Krawfish::Index::Store::V1::ForwardIndex->new;
  $self->{docs}->[$self->last_doc_id] =
    Krawfish::Index::Forward::Doc->new($doc);

  return $doc_id;
};


# Get doc from list
# (as long as the list provides random access to docs)
sub doc {
  my ($self, $doc_id) = @_;
  print_log('fwd', 'Get document for id ' . $doc_id) if DEBUG;
  return $self->{docs}->[$doc_id];
};

# Get a specific forward indexed document by doc_id
sub pointer {
  my $self = shift;
  return Krawfish::Index::Forward::Pointer->new($self);
};


1;
