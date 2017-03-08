package Krawfish::Util::BucketSort::Bucket;
use Krawfish::Log;
use strict;
use warnings;

# TODO:
#   The position should be stored in BucketSort, not in the bucket

use constant DEBUG => 0;

# The count is the sum of all counts before
sub new {
  my $class = shift;
  bless [
    0,  # count
    [], # entries
    -1  # position
  ], $class;
};


# Increment counter
sub incr {
  return ++$_[0]->[0];
};


# Entries have the structure:
# [rank
sub insert {
  my ($self, $rank, $value) = @_;

  print_log('bucket', qq!Insert value "$value" with rank $rank!) if DEBUG;

  # Increment counter
  $self->incr;

  push @{$self->[1]}, [$rank, $value];
};


sub clear {
  print_log('bucket', 'Clear unused bucket') if DEBUG;
  $_[0]->[1] = undef;
};

sub sort {
  warn 'Inner bucket sort not implemented yet';
};


# Iterate through the bucket
sub next {
  my $self = shift;

  # Initial next on bucket
  if ($self->[2] == -1) {
    $self->sort;
  };

  # go to next entry
  $self->[2]++;

  if (DEBUG) {
    print_log('bucket', 'Move to record ' . $self->[2] . ' in the bucket');
  };

  return 1 if $self->[1]->[$self->[2]];

  if (DEBUG) {
    print_log('bucket', 'No more records in bucket');
  };

  return;
};

# Get current record
sub current  {
  my $self = shift;
  return $self->[1]->[
    $self->[2]
  ];
};

sub to_histogram {
  my $self = shift;
  return join('', map { '[' . $_->[0] . ':' . $_->[1] . ']' } @{$self->[1]});
};

1;
