package Krawfish::Query::Util::BucketSort;
use Krawfish::Query::Util::BucketSort::Bucket;
use Krawfish::Log;
use strict;
use warnings;
use bytes;

# All K::Q::Util packages may move to K::Util ...

# This implements the datastructure for all bucket sorts algorithms.
# It will initially

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
#  The implementation may well be a double-linked list where
#  bucket borders are additional links to the list:
#
#  [buc1=count|valid][buc2=count|valid]...
#      |                 |----------------|
#      |                                  |
#      v                                  v
#  [rec1|dupl]=[rec2|dupl]=[rec3|dupl]=[rec4|dupl]=...
#
# With this, it's possible to first use bucket search
# for insertion into the list and then perform insertion
# sort or any other offline sort algorithm per valid bucket.
# However - the length of the list needs to be transported
# somehow ... maybe by a separated link with the bucket pointers.

sub new {
  my $class = shift;
  my $top_k = shift;

  my @buckets = ();
  foreach (0 .. 255) {
    push @buckets, Krawfish::Query::Util::Buckets::Bucket->new;
  };

  bless {
    top_k => $top_k,
    buckets => \@buckets,
    max_bucket => 256
  }, $class;
};


sub add {
  my ($self, $rank, $record) = @_;

  # This returns the first 8 bits from the rank
  my $bucket_nr = bytes::substr($rank, 0, 1);

  # Check, if bucket is valid
  return unless $bucket_nr > $self->{max_bucket};

  # Buckets have the structure:
  # [valid|pointer|counter]
  my $bucket = $self->{buckets}->[$bucket_nr];

  # Insert (sorted)
  $bucket->insert($rank, $record);

  # Bucket is in max
  return 1 if $bucket_nr == $self->{max_bucket};

  # Increment bucket counter
  while ($bucket = $self->{buckets}->[$bucket_nr++]) {

    # Increnment bucket and invalidate if exceeding
    if ($bucket->incr > $self->{top_k}) {
      $self->{max_bucket} = $bucket_nr - 1;
      last;
    };
  };

  return 1;
};


# Returns the top k results in sorted bucket order
sub next;

1;
