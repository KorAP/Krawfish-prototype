package Krawfish::Index::Fields;
use Krawfish::Index::Fields::Doc;
use Krawfish::Index::Fields::Ranks;
use Krawfish::Index::Fields::Pointer;
use Krawfish::Log;
use warnings;
use strict;

use constant DEBUG => 1;


# TODO:
#   Reranking a field is not necessary, if the field value is already given.
#   In that case, look up the dictionary if the value is already given,
#   take the example doc of that field value and add the rank of that
#   doc for the new doc.
#   If the field is not yet given, take the next or previous value in dictionary
#   order and use the rank to rerank the field (see K::I::Dictionary).
#   BUT: This only works if the field has the same collation as the
#   dictionary!


# Merging the fields index is pretty simple, as it only needs to be indexed
# on the document level and then simply be appended.

# Sort documents by a field and attach a numerical rank.
# Returns the maximum rank and a vector of ranks at doc id position.
# Ranks can be set multiple timnes
#
# TODO:
#   These ranks may also be used for facet search, because
#   remembering the ranks and increment their values will
#   return the most common k facets of the field quickly.
#   Returning the fields per rank, however, may become
#   a linear search for the first rank in the ranked fields,
#   which may be slow.
#   But nonetheless, the max_rank field may also give a hint,
#   if the field is good for faceting! (unique ranks per field
#   are bad, for example!)


# Constructor
sub new {
  my $class = shift;
  bless {
    docs => [],
    last_doc_id => -1,
    ranks => {}
  }, $class;
};


# Get last document identifier aka max_doc_id
sub last_doc_id {
  $_[0]->{last_doc_id};
};


# Accepts a Krawfish::Koral::Document
sub add {
  my ($self, $doc) = @_;
  my $doc_id = $self->{last_doc_id}++;

  # TODO:
  #   use Krawfish::Index::Store::V1::Fields->new;
  $self->{docs}->[$self->last_doc_id] =
    Krawfish::Index::Fields::Doc->new($doc);
  return $doc_id;
};


# Get doc from list (as long as the list provides random access to docs)
sub doc {
  my ($self, $doc_id) = @_;
  print_log('fields', 'Get document for id ' . $doc_id) if DEBUG;
  return $self->{docs}->[$doc_id];
};


# Get a specific forward indexed document by doc_id
sub pointer {
  my $self = shift;
  return Krawfish::Index::Fields::Pointer->new($self);
};


1;


__END__
