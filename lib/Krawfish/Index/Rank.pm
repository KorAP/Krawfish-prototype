package Krawfish::Index::Rank;
use strict;
use warnings;

# Base class for ranking of fields and subterms

# Strategy:
#
#   SURFACE RANKING
#   ===============
#   The dictionary contains all ranking information for surface forms.
#   When a surface form is added, the information on the ranking in
#   the dynamic dictionary is stored as empty epsilon information initially.
#   (See the store variant of the static dictionary).
#   Every new term in the dynamic dictionary is added to a list of
#   terms with attached term ids.
#   Identical surface terms may have different sorting keys (following
#   UTS #10) - in that case, before the ranking transition, another transition
#   is added to branch on multiple sorting keys, e.g.
#   bank-[COLL-DE]-[RANKS1]-#term-id-1
#      \-[COLL-EN]-[RANKS2]-#term-id-2
#   (Or the collations are appended to the ranking level)
#   In the forward index, the different term-ids result in different rankings,
#   though they result in identical surface terms.
#   That way, different languages can be sorted at the same time solely based
#   on their sorting key.
#   BE AWARE: For checking, if a term is identical to another term,
#   the collation must be stored in a byte at the rank transition.
#   Because this may introduce quie a lot of problems, it's up to changes.
#
#   On MERGE
#     1 The dictionaries are merged
#     2 The list of new terms is sorted both in prefix and
#       suffix order according to their UTS #10 sorting keys
#     3 The sorted new term list in prefix order is merged with the
#       sorted list in prefix order of the static dictionary
#     4 When a new term is first found to be merged in,
#       the term gets the prefix rank in the merged static dictionary
#     5 All following terms are updated in the static dictionary
#       accordingly
#       (which is fast, because term-id lookup + one up is reasonable
#       fast in memory)
#     6 Do 2-5 for the suffix ordered list
#
#   The dynamic new term list (unsorted) has the following structure:
#     ([sorting-key][term_id])*  # though, this may be redundant
#   The static sorted lists have the following structure:
#     ([sorting-key-with-front-coding][term_id])*
#   Ranks are stored at the pre-terminal level in the dictionary.
#
#   Ranking information is stored on the node level
#     [term_id] -> [RANK]
#     ->rank_by_term_id(term_id)
#     ->rev_rank_by_term_id(term_id)
#
#
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
#
#
#   COLLATIONS
#   ==========
#   Sortable fields need to be initialized before documents using
#   this field are added. The dictionary will have a "sortable" flag
#   on a pre-terminal edge in the dictionary that is retrievable.
#   when a field is requested, that is not sortable, an error is raised
#   when the sorting is initialized.
#   The collation file is sorted by field-term-id and probably quite short
#   and kept in memory
#
#     ([sortable-field-id][collation])*
#
#   When a new field is initialized, this list is immediately updated.
#
#   Collation information is stored on the node level
#     [term_id] -> [COLLATION]
#     ->init_field(field, collation)
#     ->collation_by_field_id(field_id)
#
#   Because collation for fields is also stored per segment, this is not
#   requested often.


# TODO:
#   For encoding dense but not diverse field ranks use something like that:
#   http://pempek.net/articles/2013/08/03/bit-packing-with-packedarray/
#   https://github.com/gpakosz/PackedArray
#   That's why max_rank is important, because it indicates
#   how many bits per doc are necessary to encode
#   the rank!
#
# TODO:
#   In case, a field is only set for a couple of documents, a different
#   strategy may be valid.

# TODO:
#   Think about a different design, where the field lists are stored on the
#   node level:
#     [collation]([field-term-with-front-coding][term_id])
#   Now, the new terms will be merged in the list and the new segment will incorporate
#   the new ranking.
#   When a new term is added, it is added as
#     ([term][term_id][doc_id])*
#   ...

sub max {
  $_[0]->{max};
};


# Needs to be implemented
# in the child modules
sub merge {
  ...
};


1;
