package Krawfish::Query::Util::BucketSort::Bucket;
use Krawfish::Query::Util::BucketSort::Record;
use Krawfish::Log;
use strict;
use warnings;

# The count is the sum of all counts before
sub new {
  bless [
    0, # count
    [] # entries
  ], shift;
};


# Increment counter
sub incr {
  return $_[0]->[1]++;
};


# Entries have the structure:
# [rank
sub insert {
  my ($self, $rank, $value) = @_;

  # Increment counter
  $self->incr;

  # Insert into list
  # Probably unsorted at first
  $self->{list}->insert($rank, $value);
};


1;
