package Krawfish::Search::FieldSort;
use strict;
use warnings;

# TODO:
#   This is just an experiment!
# TODO:
#   Use a variant of insertion sort or (better) tree sort
#   http://jeffreystedfast.blogspot.de/2007/02/binary-insertion-sort.html
# TODO:
#   Whenever top X is requested, and there are matches > X with a max_rank Y,
#   ignore all matches > Y. This also means, these matches do not need to be
#   fine-sorted using secondary fields.
# TODO:
#   This should - as a by product - count frequencies
sub new {
  my $class = shift;
  my $self = bless {
    query => shift,
    index => shift,
    sort_by => [@_]
  }, $class;

  my $query = $self->{query};
  my $index = $self->{index};

  # Fields
  my $fields = $index->fields;

  # TODO: This should be a linked list!
  my @record_order;
  my @equally_ranked;

  # First pass sort
  my $i = 0;
  my $sort_by = $self->{sort_by}->[$i++];
  my ($max_rank, $rank) = $fields->docs_ranked($sort_by[$i]);

  # TODO:
  #   This may need to create a cached result buffer
  #   and a linked list with offset information augmented.
  #   That way it's trivial to resort the document later on!

  # TODO: Probably use next_doc
  #
  # TODO: This requires a cached buffer
  while ($query->next) {

    # This should
    my $current = $query->current;
    my $doc_id = $current->doc_id;
    my $offset = $current->offset; # record-offset in cached buffer!

    # Get the rank of the doc in O(1)
    # If rank is not set, set max_rank + 1
    # TODO: This should be realized using the Rank-API
    my $doc_rank = $rank->[$doc_id] || ($max_rank + 1);

    # TODO: This should be added sorted
    # TODO: Use something like tree sort
    # TODO: Add identical field-docs at position 2!
    my $pos = 4; # is a pointer to the first identical element in the list
    push @record_order, [$offset, $doc_rank];

    # There are identical fields ...
    if ($record_order[$pos - 1] eq $record_order[$pos]) {

      # TODO: Only mark the first identical occurrence
      push @equally_ranked, $pos - 1;
    };
  };


  # nth pass fine-sort - Iterate over remaining fields
  # If there are remaining unsorted fields at the end, sort by identifier
  for (; $i <= @{$self->{sort_by}}; $i++) {
    $sort_by = $self->{sort_by}->[$i];

    # Get the rank of the field
    # This should probably be an object instead of an array
    $rank = $fields->docs_ranked($sort_by);

    # At the beginning, iterate over all docs

    # The list is already sorted by former fields - refine!
    if (@equally_ranked) {
      ...
    }

    # The list is already finally ranked
    else {
      last;
    };
  };

  # record_order now contains a linked list of offsets
  # to the cached buffer
  #
  # The next etc. should be nextable!

  return $self;
};

# Iterated through the ordered linked list
sub next {
  ...
};

1;
