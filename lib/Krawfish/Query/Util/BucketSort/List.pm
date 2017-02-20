package Krawfish::Query::BucketSort::List;
use strict;
use warnings;

# Implement as a linked list - initially unsorted
# (because it may not be necessary to sort)!
# Entries have the structure [rank|value]

sub new {
  my $class = shift;
  bless [], $class;
};

sub insert {
  my ($self, $rank, $value) = @_;
  push @$self, [$rank, $value];
};

1;
