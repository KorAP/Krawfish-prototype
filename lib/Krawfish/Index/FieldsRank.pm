package Krawfish::Index::FieldsRank;
use strict;
use warnings;

# The FieldsRank is associated to a certain field
# (like author) and may return the rank of the
# field (e.g. by lexicographic ordering) for
# a certain document ID.
#
# This is defined per Segment.
#
# TODO:
#   There are four possible rank value types:
# - value is even: The rank
# - value is odd: The prerank, means,
#   it is sorted based on the rank and takes the place
#   between the two rank values, but it may occurr
#   multiple types for different values.
# - value is 0: Not yet ranked
# - value is MAX_DOCS: Not available for this document
#   (e.g. "author" is not defined for this document)
#   TODO:
#     MAX_RANK+1 does not work very well, because it may change on every
#     RERANK ... although - it may be updated as well on every rerank,
#     so this may not be a problem.
#
# TODO:
#   Ranking is simple:
#     1. rank all values by sorting them - give them rank numbers.
#   If new values are added:
#     1. Sort all new values separately
#        Start at position i = MAX_RANK/2
#        while there are values in the list:
#        2. Look up, if the smallest value is already present
#           LOOKUP
#           yes -> ignore, keep position as i
#                  but for rank-integration, keep the rank in
#                  a special data strukture like ranked_cache
#           no -> go to 3
#        # HOW TO SEARCH HERE!?
#        3. Get the preceeding and following rank values and
#           define the middle value for the value as a prerank
#           and set position value to 0.
#        4. For all next values to prerank, look, if they have the same
#           surrounding ranks (just check, if the greater ranked value is also greater
#           as the current value).
#           yes ->
#             Check, if the value is identical
#             yes -> add known prerank and same position value, go to 2
#             no -> add known prerank and an incremented position value, go to 2
#           no -> go to 2
#   For merging, just go linearly through all
#   Ranks in a merge sort way. Whenever there is a value that needs to be integrated
#   from the prerank list, increment all values.
#   HOW:
#     The ranked list will be iterated in document order
#     The precached_rank needs to have a special data structure with an API:
#     ->update_rank(rank), that will take a rank of the ranked list
#     and returns the rank incremented by the number of preranks before this rank.
#     in case, no rank was inserted before, this will be the same.
#     Then, all new documents with preranked or ranked but not integrated yet
#     values will be appended to the rank stream.
#
# TODO:
#   Use something like that:
#   http://pempek.net/articles/2013/08/03/bit-packing-with-packedarray/
#   https://github.com/gpakosz/PackedArray
#
# TODO:
#   $max_rank is important, because it indicates
#   how many bits per doc are necessary to encode
#   the rank!
#
# TODO:
#   In case, a field is only set for a couple of documents, a different
#   strategy may be valid.
#
# TODO:
#   Rank 0 may be used to indicate a field that is not ranked yet.
#

use constant {
  NOT_RANKED_YET => 0
};

sub new {
  my $class = shift;
  my $field_array = shift;

  # Todo: Lookup at disk!

  # get ranked array
  my ($max_rank, $ranked) = _rank_str($field_array);

  bless {
    # TODO: There also need to be a max doc value, to know
    # if a doc_id needs to be looked up in prerank!
    max   => $max_rank, # TODO: May be stored + 1 for "NOT AVAILABLE"
    ranked => $ranked,
    preranked_cache => {}, # TODO: This is necessary for preranking
    ranked_cache => {} # TODO: This contains documents that have an identical rank
                       #       that already exist, but are not yet part of the rank
  }, $class;
};

sub not_available {
  $_[0]->{max} + 1;
}

# This may return 0 for "not ranked yet" or
# MAX_RANK+1 for "field not available for document",
# TODO:
#   or an even value for a rank or an odd value for a
#   prerank. If the value is preranked, add this to
#   the prerank cache as
#   doc_id => [prerank, prerank-position]
#
sub get {

  # TODO:
  #   If the value comes from the rank list, multiply with 2!
  $_[0]->{ranked}->[$_[1]];
};

# TODO:
#   Get the prerank position per doc id
sub get_prerank_pos {
  $_[0]->{preranked_cache}->[$_[1]]
};


# Get rank if the value is littler than
# a given value, otherwise return 0.
# This may be beneficially implemented.
sub get_lt {
  my ($self, $doc_id, $value) = @_;
  my $rank = $self->get($doc_id);
  return $rank if $rank < $value;
};


# Get rank if the value is greater than
# a given value, otherwise return 0.
# This may be beneficially implemented.
sub get_gt {
  my ($self, $doc_id, $value) = @_;
  my $rank = $self->get($doc_id);
  return $rank if $rank > $value;
};

# Return the rank << to the most significant position,
# so the first byte used for bucket sort will always
# Check for the most significant AND meaningful bits
sub get_significant {
  ...
};

sub max {
  $_[0]->{max};
}

# Todo: use rank_num
# SIMPLE ALGO: http://stackoverflow.com/questions/14834571/ranking-array-elements
# COMPLEX ALGO: https://www.quora.com/How-to-rank-a-list-without-sorting-it
# See http://orion.lcg.ufrj.br/Dr.Dobbs/books/book5/chap14.htm
# Use collations:
#   http://userguide.icu-project.org/collation
sub _rank_str {
  my ($array) = @_;

  # Get sorted docs by field
  my $pos = 0;
  my @sorted = sort {
    if ($a->[0] gt $b->[0]) {
      return 1;
    };
    return -1;

    # Add original position
  } map { [$_ , $pos++] } @$array;

  my @ranked;

  my $rank = 0;
  my $last = '';

  # Iterate over sorted list
  for my $i (0 .. $#sorted) {

    # Need to start a new chunk?
    if ($sorted[$i]->[0] ne $last) {
      $rank++;
      $last = $sorted[$i]->[0];
    };

    # Set rank
    $ranked[$sorted[$i]->[1]] = $rank;
  };

  # Return max_rank and ranked list
  return $rank, \@ranked;
}


1;
