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
    max => 0 # Maximum number of documents
  }, $class;
};


# Increment maximum number of documents
# (aka last_doc_id)
sub incr {
  return $_[0]->{max}++;
};


# get or set maximum document value
# aka last_doc
sub last_doc {
  my $self = shift;
  if (@_) {
    $self->{max} = shift;
  };
  return $self->{max};
};

# Delete documents
# Accepts a list of document identifier of the segment
# TODO:
#   it may be easier to delete by a given corpus query
sub delete {
  my $self = shift;
  foreach (@_) {
    push @{$self->{deletes}}, $_;
  };

  # In the store, this should probably
  # first create a list of naturally ordered document IDs
  # (because they are in order, if you search for them)
  # and then merge sort with the already given deletion list
  $self->{deletes} = [uniq sort @{$self->{deletes}}];
  return $self;
};


# Number of all live documents
sub freq {
  my $self = shift;
  $self->{max} - scalar @{$self->{deletes}}
}


sub pointer {
  my $self = shift;
  # This requires a list copy, so chenages in the list
  # do not change pointer behavious
  Krawfish::Index::PostingLivePointer->new(
    $self->{deletes},
    $self->{max}
  );
};

sub to_string {
  my $self = shift;
  '~' . join(',', map { '[' . $_ . ']' } @{$self->{deletes}});
};


1;
