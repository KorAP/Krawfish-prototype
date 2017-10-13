package Krawfish::Index::Fields::Ranks;
use Krawfish::Index::Fields::Rank;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

#   FIELD RANKING
#   =============
#   Each segment contains all ranking information for sortable fields.
#   When a document is added to the dynamic segment, all sortable fields
#   are recognized with their sorting keys and the attached doc id.
#   Each static segment has a rank file per field with the length of
#   the segment's doc vector including a forward rank and a backward rank.
#   To make reranking possible on merging, each static segment also has a
#   sorted list of sorting keys with all documents the field is attached to.
#   To deal with multivalued fields (e.g. keywords), the ranking file has
#   two fields: One for forward sorting, one for backwards sorting.
#
#   On MERGE
#     1 Sort the dynamic field list in alphabetically/numerical order
#       (respect a chosen collation)
#     2 Merge all postingslists, forward indices etc.
#     3 Merge the dynamic field list with the static field list
#     4 Iterate through the new list from beginning to the end to
#       fill the forward ranking list. Increment starting with 1.
#       The first occurrence of a doc_id is taken.
#       The maximum rank is remembered.
#     5 Iterate through the new list from beginning to the end to
#       fill the reverse ranking list. Decrement stating with the maximum rank.
#       The last occurrence of a doc_id is taken.
#     6 Based on the relation between maximum rank and the length of the
#       document vector, the ranking file is encoded and stored.
#       The number of unset documents may also be taken into account for encoding.
#
#   The sorted lists have the following structure:
#     [collation]([sort-key-with-front-coding|value-as-delta][num-doc-ids-varint][doc_id]*)*
#   The dynamic field list (unsorted) has the following structure:
#     ([field-term][doc_id])*
#   The static ranking lists have the following structure:
#     ([rank][revrank]){MAX_DOC_ID}
#
#   Ranking information is stored on the segment level
#     [doc_id] -> [RANK]
#     ->rank_by_doc_id(doc_id)
#     ->rev_rank_by_doc_id(doc_id)


# TODO:
#   Instead of 'by()', implement
#   'ascending()' and 'descending()!'
#   And store the information, if a field
#   has multiple values in the ranks overfiew


# Constructor
sub new {
  my $class = shift;

  # Should have the structure:
  # { field_id => [asc_rank, desc_rank?] }
  # If desc_rank is undefined, get the
  # asc_rank for descending values and calculate
  # using max_rank
  bless {}, $class;
};


# Get the rank by field
sub by {
  my ($self, $field_id) = @_;

  if (DEBUG) {
    print_log('f_ranks', 'Retrieve ranks for #' . $field_id);
  };

  # Field may be ranked or not
  return $self->{$field_id};
};


# Introduce rank for a certain field
sub introduce_rank {
  my ($self, $field_id, $collation) = @_;

  if (DEBUG) {
    print_log('f_ranks', 'Introduce rank for field #' . $field_id .
                ' with collation ' . ($collation ? $collation : 'numerical'));
  };

  $self->{$field_id} = Krawfish::Index::Fields::Rank->new($collation);
};


# Commit uncommitted data
sub commit {
  my $self = shift;

  if (DEBUG) {
    print_log('f_ranks', 'Commit ranks');
  };

  # This can eventually be parallelized
  $_->commit foreach values %$self;

  return 1;
};


# Stringification
sub to_string {
  my $self = shift;
  return join(';', map { $_ . ':' . $self->{$_}->to_string } keys %$self);
};

1;
