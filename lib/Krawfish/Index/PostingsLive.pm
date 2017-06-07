package Krawfish::Index::PostingsLive;
use List::MoreUtils qw/uniq/;
use Krawfish::Index::PostingLivePointer;
use strict;
use warnings;

# Similar interface as Krawfish::Index::PostingsList,
# but has a "delete" method.

# TODO:
#   In addition, this will store the maximum
#   number of documents.


sub new {
  my ($class, $index_file) = @_;
  bless {
    index_file => $index_file,
    deletes => [],
    pointers => [],
    next_doc_id => 0
  }, $class;
};


# Increment maximum number of documents
# (aka last_doc_id)
sub incr {
  return $_[0]->{next_doc_id}++;
};


# get or set maximum document value
# aka last_doc
sub next_doc_id {
  my $self = shift;
  if (@_) {
    $self->{next_doc_id} = shift;
  };
  return $self->{next_doc_id};
};


# Delete documents
# Accepts an ordered list of document identifier of the segment
sub delete {
  my $self = shift;

  # Check for sorting - this is necessary for transaction based
  # merge sort
  my $old = -1;
  my @list;
  foreach (@_) {
    if ($_ <= $old) {
      return;
    };
    $old = $_;
    push @list, $_;
  };

  # In the store, this should probably
  # first create a list of naturally ordered document IDs
  # (because they are in order, if you search for them)
  # and then merge sort with the already given deletion list
  $self->{deletes} = [uniq sort (@{$self->{deletes}}, @list)];
  return $self;
};


# Number of all live documents
sub freq {
  my $self = shift;
  return $self->{next_doc_id} - scalar @{$self->{deletes}}
};


sub pointer {
  my $self = shift;
  # This requires a list copy, so chenages in the list
  # do not change pointer behavious
  Krawfish::Index::PostingLivePointer->new(
    $self->{deletes},
    $self->{next_doc_id}
  );
};

sub to_string {
  my $self = shift;
  '~' . join(',', map { '[' . $_ . ']' } @{$self->{deletes}});
};


1;
