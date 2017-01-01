package Krawfish::Result::Sort;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

# TODO:
#   Use a variant of insertion sort or (better) tree sort
#   http://jeffreystedfast.blogspot.de/2007/02/binary-insertion-sort.html
#   The most natural way to sort would probably be a variant of bucket sort,
#   but this would perform poorly in case the field to sort has only
#   a single rank, which would be the case, if the corpus query would require
#   this.
#   The best variant may be bucket sort with insertion sort. In case top_n was chosen,
#   this may early make some buckets neglectable.
#   Like this:
#   1. Create 256 buckets. These buckets have
#      1.1. A pointer to their contents and
#      1.2. A counter, how many elements are in there.
#           If the pointer is zero, no elements should
#           be put into the bin (i.e. forget them).
#      1.3. A bit vector marking equal elements
#           May not be good - better add concrete pointers, because
#           order will change regularly. Maybe only a single
#           marker for duplicates
#   2. Get a new item from the stream and add it to the bucket in question,
#      in case this bucket does not point to 0.
#      2.1. Do an insertion sort in the bucket.
#      2.2. If the elements are equal, put the element behind the equal element
#           and set the duplicate flag.
#   3. Increment the counter of the bucket.
#   4. If the number of sorted elements is (n % top_n) == 0
#      iterate through all buckets from the top and calculate the sum
#      of the contents.
#      4.1. If the sum exceeds top_n, clean up the following bucket pointers
#           and let them point to 0.
#      4.2. Stop if a pointer is 0.
#   5. Go to 2 until all elements are consumed.
#   6. From the top bucket, check all duplicates, and sort them after the next field
#   7. Go to 6. unless all fields are sorted.
#   8. Check for remaining duplicates in the buckets and sort them by the uid field.
#   9. Return top_n in bucket order.
#
#   It would be great, if the ordered values in the buckets could be used
#   for traversing directly - without copying the structure any further.
#   As the top-buckets will always receive items, they will probably need more space than the others
#   (although, this is not true all the time)
#
#   To calculate the sum of the preceeding array, vector intrinsics may be useful:
#   http://stackoverflow.com/questions/11872952/simd-the-following-code
#
# TODO:
#   Whenever top X is requested, and there are matches > X with a max_rank Y,
#   ignore all matches > Y. This also means, these matches do not need to be
#   fine-sorted using secondary fields.
#
# TODO:
#   This should - as a by product - count frequencies
#
# TODO:
#   This should also release top items as early as possible
#
# TODO:
#   This should bin-sort everything in case it's called using a streaming API
#
sub new {
  my $class = shift;
  my $self = bless {
    query => shift,
    index => shift,
    fields => shift,
    freq => 0,
    pos => -1, # Temporary
    # top_k => shift // 0 # TODO!
  }, $class;

  my $query = $self->{query};
  my $index = $self->{index};

  # Fields
  my $field_obj = $index->fields;

  my @record_order; # Currently contains clones!

  # TODO:
  my @equally_ranked;

  # First sort criteria
  my $i = 0;
  my $sort_by = $self->{fields}->[$i++];
  my $rank = $field_obj->ranked_by($sort_by);

  # TODO:
  #   This may need to create a cached result buffer
  #   and a linked list with offset information augmented.
  #   That way it's trivial to resort the document later on!

  # TODO: Probably use next_doc
  #
  # TODO: This requires a cached buffer
  while ($query->next) {

    print_log('c_sort', 'Get next posting from query ' . $query->to_string) if DEBUG;

    # Add cloned
    my $element = $query->current->clone;
    push @record_order, $element;
    $self->{freq}++;

    print_log('c_sort', 'Clone ' . $element->to_string) if DEBUG;

    # TODO:
    # my $offset = $current->offset; # record-offset in cached buffer!

    # Get the rank of the doc in O(1)
    # If rank is not set, set max_rank + 1

    # TODO: This should be added sorted
    # TODO: Use something like tree sort
    # TODO: Add identical field-docs at position 2!
    # my $pos = 4; # is a pointer to the first identical element in the list
    # push @record_order, [$offset, $doc_rank];

    # There are identical fields ...
    # if ($record_order[$pos - 1] eq $record_order[$pos]) {
    #   # TODO: Only mark the first identical occurrence
    #   push @equally_ranked, $pos - 1;
    # };
  };

  print_log('c_sort', 'Check ranking') if DEBUG;

  my $max = $rank->max;
  $self->{ordered} = [sort {
    my $rank_a = $rank->get($a->doc_id) || ($max + 1);
    my $rank_b = $rank->get($b->doc_id) || ($max + 1);
    return $rank_a <=> $rank_b;
  } @record_order];

  print_log(
    'c_sort',
    "Ordered by rank '$sort_by' is " . join(',', @{$self->{ordered}})
  ) if DEBUG;

  return $self;


  # TODO:

  # nth pass fine-sort - Iterate over remaining fields
  # If there are remaining unsorted fields at the end, sort by identifier
  for (; $i <= @{$self->{sort_by}}; $i++) {
    $sort_by = $self->{sort_by}->[$i];

    # Get the rank of the field
    # This should probably be an object instead of an array
    $rank = $field_obj->ranked_by($sort_by);

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
  my $self = shift;
  if ($self->{pos}++ < ($self->freq - 1)) {
    return 1;
  };
  return;
};


# Get frequency
sub freq {
  $_[0]->{freq};
};

sub current {
  my $self = shift;
  return $self->{ordered}->[$self->{pos}] // undef;
};

sub to_string {
  my $self = shift;
  my $str = 'collectSorted(';
  $str .= '[' . join(',', map { _squote($_) } @{$self->{fields}}) . ']:';
  $str .= $self->{query}->to_string;
  return $str . ')';
};

# From Mojo::Util
sub _squote {
  my $str = shift;
  $str =~ s/(['\\])/\\$1/g;
  return qq{'$str'};
};


1;
