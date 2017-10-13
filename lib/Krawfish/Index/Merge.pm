package Krawfish::Index::Merge;
use strict;
use warnings;

# TODO:
#   This is not an actual implementation,
#   just a guide to keep notes what is necessary
#   to merge two segments and two dictionaries.


# There are two types of segments:
# a) multiple static segments
# b) One dynamic segment
#
# All new documents are added to the dynamic index.


# Constructor
sub new {
  my ($class, $segment_a, $segment_b) = @_;
  bless {
    segment_a => $segment_a,
    segment_b => $segment_b
  }, $class;
};


# Merge segments
sub merge {

  # Merging will:
  # - Concatenate all postings lists
  $self->_merge_postings_lists;

  # - concatenate field information
  #   - This is also necessary for reranking
  $self->_merge_fields;

  $self->_merge_forward;

  $self->_merge_live;

  # - concatenate docid->uuid field mappers
  # $self->_merge_identifier_lists;

  # - concatenate all subtoken lists
  # $self->_merge_subtoken_lists;

  # - Rerank all field ranks
  #   (ignoring deleted documents)
  #   - Update pointer file to the dictionary (or maybe not)
  # - This requires, that the "get_field(x)" is already
  #   prepared for both indices
  $self->_rerank_fields;

  # - Concatenate and update primary files / forward index
  # $self->_merge_primary_data;

  # In case the second index is dynamic, also
  # Merge the dictionaries
  if ($index_b->is_dynamic) {
    $index_a->dict->merge($index_b->dynamic_dict);
  };

  # Launch the newly created index
  $self->_launch;
};


sub _launch {
  # TODO:
  #   - If the dictionary is new
  #       - lock the whole index
  #       - Switch to the new dictionary
  #       - remove the old dictionary
  #       - remove segment A
  #       - remove segment B
  #       - activate the new segment
  #     else
  #       - lock segment A
  #       - lock segment B
  #       - activate the new segment
  #       - remove segment A
  #       - remove segment B
};


sub _merge_postings_lists {
  # TODO:
  #   (ignore deleted documents)
  #   - Add SkipLists to postings lists
  #   - Update position information in dictionary
  #     (or rather in the pointer file per segment)
  #   - Decrement all document ids for deleted documents
  #   - Add the maximum doc_id of the first segment to
  #     all documents of the second index
  #   - Calculate new freq value
};


sub _merge_fields {
  # TODO:
  #   (ignore deleted documents)
  #   - Take all field information and write them in a new file
  #   - Update all pointing information that maps doc_id->field_pos
};


sub _merge_subtoken_lists {
  #   (ignore deleted documents)
  #   - Take all subtoken lists and write them to a new file
  #   - The position offsets to the primary data files should stay intact
};


sub _merge_primary_data {
  # TODO:
  #   (ignore deleted documents)
  #   - Take all primary data and write them in a new file
  #   - Update all pointing information that maps doc_id->primary_pos
  #   - The position pointer offsets in the subtoken-lists should stay intact
};


sub _rerank_fields {
  # TODO:
  #   (ignore deleted documents)
  #   Case A) At the beginning the mechanism has two field ranks:
  #
  #   A  Version:24; Max:4; 3,4,3,1
  #   B  Version:28; Max:5; 3,5,2,1
  #
  #   Both ranks have different dictionary version numbers, which means
  #   the ranks may differ. To get this information, if there is, e.g.
  #   A new field ranked between 1 and 2, the field backlog of the
  #   dictionary is requested with the structure:
  #
  #   author:
  #     V25:
  #       Goethe: 3 (means: Goethe was inserted before 3!)
  #     V27:
  #       Schiller: 9
  #
  #   First: The maximum rank is looked up and incremented so it is checked
  #   if the max-value is needs to be updated. Then it is checked, which max-value
  #   is the new max, which is then used as the new max (dictating the bit width).
  #
  #   Based on that information the rank list of the older version is updated by
  #   incrementing old ranks by the number of new ranks in between.
  #
  #   Then both ranks are concatenated.
  #
  #   In case the max value was introduced by a then-deleted document,
  #   update the max value (though do not update the bitwidth again).


  #   Case B) At the beginning, one segment has a field rank, the other has none:
  #
  #   A  Version:24; Max:4; 3,4,3,1
  #   B
  #
  #   In that case B first needs to get a field rank


  #   Case C) At the beginning, no segment has a field rank:
  #
  #   A
  #   B
  #
  #   In that case, concatenate first, then rank.
  #   Take the maximum rank and use this for encoding
};


1;
