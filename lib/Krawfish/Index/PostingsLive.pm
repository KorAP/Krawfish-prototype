package Krawfish::Index::PostingsLive;

# Similar interface as Krawfish::Index::PostingsList

use strict;
use warnings;

# TODO:
#   Has a "delete" method and works
#   otherwise identical to PostingsList and
#   PostingPointer

sub new {
  my ($class, $index_file, $max) = @_;
  bless {
    index_file => $index_file,
    deletes => [],
    pointers => [],
    max => $max # Maximum number of documents
  }, $class;
};

# Delete documents
# Accepts a list of document identifier of the segment
# TODO:
#   it may be easier to delete by a given corpus query
sub delete_by_ids {
  my $self = shift;
  foreach (@_) {
    push @{$self->{deletes}}, $_;
  };

  # In the store, this should probably
  # first create a list of naturally ordered document IDs
  # (because they are in order, if you search for them)
  # and then merge sort with the already given deletion list
  $self->{deletes} = [sort @{$self->{deletes}}];
};


sub freq {
  $_[0]->{max} - scalar @{$self->{deletes}}
}

sub pointer {
  my $self = shift;
  Krawfish::Index::PostingLivePointer->new($self);
};

sub to_string {
  my $self = shift;
  '~' . join(',', map { '[' . $_ . ']' } @{$self->{deletes}});
};

# Pointer actions
sub next {
  my $self = shift;
  my $pos = $self->{pos}++;

  if ($pos + 1 < $self->freq) {
    if ($self->{deletes}) {
      ...
    }
  };

  return;
};

1;
