package Krawfish::Index::FieldsRank;
use strict;
use warnings;

# TODO:
#   $max_rank is important, because it indicates
#   how many bits per doc are necessary to encode
#   the rank!
#
# TODO:
#   Use something like that:
#   http://pempek.net/articles/2013/08/03/bit-packing-with-packedarray/
#   https://github.com/gpakosz/PackedArray
#
sub new {
  my $class = shift;
  my $field_array = shift;

  # Todo: Lookup at disk!

  # get ranked array
  my ($max_rank, $ranked) = _rank_str($field_array);

  bless {
    max   => $max_rank,
    ranked => $ranked
  }, $class;
};

sub get {
  $_[0]->{ranked}->[$_[1]];
};


# Return the rank on a scale of 0-255
sub get_mapped {
  ...
};

sub max {
  $_[0]->{max};
}

# Todo: use rank_num
# SIMPLE ALGO: http://stackoverflow.com/questions/14834571/ranking-array-elements
# COMPLEX ALGO: https://www.quora.com/How-to-rank-a-list-without-sorting-it
# See http://orion.lcg.ufrj.br/Dr.Dobbs/books/book5/chap14.htm
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
