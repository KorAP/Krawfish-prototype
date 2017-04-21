package Krawfish::Index::Rank::Fields;
use parent 'Krawfish::Index::Rank';
use strict;
use warnings;

# The FieldsRank is associated to a certain field
# (like author) and may return the rank of the
# field (e.g. by lexicographic ordering) for
# a certain document ID.
#
# This is defined per Segment.

# TODO:
#   There are two possible rank value types:
# 1 VALUE IS >= 1 && <= MAX_RANK:
#   The rank in the segment
# 2 VALUE IS 0: Not available for this document
#   (e.g. "author" is not defined for this document)

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
