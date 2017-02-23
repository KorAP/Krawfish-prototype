package Krawfish::Util::BucketSort;
use strict;
use warnings;
use Krawfish::Util::BucketSort::Bucket;
use Krawfish::Log;
use POSIX qw/floor ceil/;
use bytes;

use constant DEBUG => 1;

# All K::Q::Util packages may move to K::Util ...


# TODO:
#   BucketSort may not be well suited for top_k sorting,
#   but it may be useful for grouping - because after
#   sorting all matches into 256 buckets, groups can be constructed in parallel!


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
  my ($class, $top_k, $max_rank) = @_;

  # TODO: Optimize
  # if ($max_rank < 256) {
  #   ...
  # };

  my @buckets = ();
  foreach (0 .. 255) {
    push @buckets, Krawfish::Util::BucketSort::Bucket->new;
  };

  bless {
    top_k      => $top_k,
    buckets    => \@buckets,
    max_rank   => $max_rank,  # TODO: This is temporary!
    max_bucket => 256,        # All buckets are initially valid
    pos => -1,
    pos_bucket => 0
  }, $class;
};


# Scale rank down to 0-255
sub _temp_bucket_nr ($$) {
  my ($rank, $max_rank) = @_;
  my $ret = ceil(($rank / $max_rank) * 256) -1;
  return $ret < 0 ? 0 : $ret;
};


sub add {
  my ($self, $rank, $record) = @_;

  if ($self->{pos} != -1) {
    warn 'Not allowed to add to sort';
    return;
  };

  # TODO:
  # This should return the first 8 bits from the rank!
  # my $bucket_nr = bytes::substr($rank, 0, 1);
  my $bucket_nr = _temp_bucket_nr($rank, $self->{max_rank});

  print_log('buckets', "Add record to bucket $bucket_nr") if DEBUG;

  # Check, if bucket is valid
  return if $bucket_nr > $self->{max_bucket};

  # Buckets have the structure:
  # [valid|pointer|counter]
  my $bucket = $self->{buckets}->[$bucket_nr];

  # Insert (sorted)
  $bucket->insert($rank, $record);

  print_log('buckets', 'Record inserted with rank information') if DEBUG;

  # TODO:
  #   Simple optimization before SIMD instructions can be used:
  #   Wait until top_k * 2 entries are sorted, then run the counter
  #   through all buckets once before doing it as before

  # Bucket is in max
  return 1 if $bucket_nr == $self->{max_bucket};

  # Increment bucket counter
  while ($bucket = $self->{buckets}->[$bucket_nr++]) {

    # Increment bucket and invalidate if exceeding
    # TODO: This incrementation may better be done using SIMD instructions
    if ($bucket->incr > $self->{top_k}) {

      print_log('buckets', 'Bucket count is greater than top_k') if DEBUG;

      # Bucket is no longer of interest
      $bucket->clear;

      $self->{max_bucket} = $bucket_nr -1;

      print_log('buckets', 'New max bucket is ' . $self->{max_bucket}) if DEBUG;

      # TODO: Potentially clear up all following buckets as well
      last;
    };
  };

  return 1;
};


# Returns the top k records in sorted bucket order
# That means, there may be duplicate entries
sub next {
  my $self = shift;

  # Get next bucket
  while (my $bucket = $self->{buckets}->[$self->{pos_bucket}]) {

    print_log('buckets', 'Read record from bucket ' . $self->{pos_bucket}) if DEBUG;

    # Return record from bucket ...
    return 1 if $bucket->next;

    print_log('buckets', 'No more records from ' . $self->{pos_bucket}) if DEBUG;

    # ... or move to next bucket
    # and forget current!
    $bucket->clear;
    $self->{pos_bucket}++;

    # Max bucket is reached
    return if $self->{pos_bucket} > $self->{max_bucket};
  };

  # Nothing to return
  return;
};

sub current {
  $_[0]->{buckets}->[$_[0]->{pos_bucket}]->current;
};

sub to_histogram {
  my $self = shift;
  my $str = '';
  foreach (0..255) {
    my $hist = $self->{buckets}->[$_]->to_histogram or next;
    $str .= sprintf("%3d", $_) . ': ' . $hist  . "\n";
  };
  $str;
};

1;
