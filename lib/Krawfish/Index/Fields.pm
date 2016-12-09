package Krawfish::Index::Fields;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

sub new {
  my $class = shift;
  bless {
    file => shift,
    array => [], # doc array
    ranks => {}, # ranked lists
    identifier => shift
  }, $class;
};

sub store {
  my $self = shift;
  my $doc_id = shift;
  my ($key, $value) = @_;

  # Preset fields with doc_id
  my $fields = ($self->{array}->[$doc_id] //= {});

  print_log(
    'fields',
    'Store field ' . $key . ':' . $value . ' for ' . $doc_id
  ) if DEBUG;

  # TODO:
  #   This needs to have information whether it's a string
  #   or an integer (mainly for sorting)
  $fields->{$key} = $value;
};

sub get {
  my $self = shift;
  my $doc_id = shift;
  my $doc = $self->{array}->[$doc_id];

  # Get specific field
  if (@_) {
    print_log(
      'fields',
      'Get field ' . $_[0] . ' for ' . $doc_id
    ) if DEBUG;

    return $doc->{$_[0]} ;
  };

  # Get all fields
  return $doc;
};


# Return documents by array
sub docs {
  return $_[0]->{array};
};


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
#
# TODO:
#   Return object
#
sub docs_ranked {
  my ($self, $field) = @_;

  print_log(
    'fields',
    'Get rank vector for ' . $field
  ) if DEBUG;

  # TODO:
  #   Currently ranks are set absolutely - but they should be set
  #   multiple times to make sorts for multiple fields
  #
  # TODO: Check if the field needs to be sorted
  #   numerically or based on a collation

  if ($self->{ranks}->{$field}) {

    # Lookup at disk
    return @{$self->{ranks}->{$field}};
  };

  # TODO:
  #   $max_rank is important, because it indicates
  #   how many bits per doc are necessary to encode
  #   the rank!
  #
  my ($max_rank, $ranked) = rank_str(
    [grep { defined $_ } map { $_->{$field} } @{$self->{array}}]
  );

  # Store ranks for the future
  $self->{ranks}->{$field} = [$max_rank, $ranked];

  if (DEBUG) {
    print_log(
      'fields',
      'Return rank vector for ' . $field . ' with ' . join(',', @$ranked)
    );
  };

  # Return ranked list
  return @{$self->{ranks}->{$field}};
};


# Todo: use rank_num
# SIMPLE ALGO: http://stackoverflow.com/questions/14834571/ranking-array-elements
# COMPLEX ALGO: https://www.quora.com/How-to-rank-a-list-without-sorting-it
# See http://orion.lcg.ufrj.br/Dr.Dobbs/books/book5/chap14.htm
sub rank_str {
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
