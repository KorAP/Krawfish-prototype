package Krawfish::Index::PostingsLive;

# Similar interface as Krawfish::Index::PostingsList

# TODO:
#   In addition, this will store the maximum
#   number of documents.

use strict;
use warnings;

# TODO:
#   Has a "delete" method and works
#   otherwise identical to PostingsList and
#   PostingPointer

sub new {
  my ($class, $file) = @_;
  bless {
    file => $file,
    deletes => [],
    pointers => [],
    max => 0 # Maximum number of documents
  }, $class;
};

sub incr {
  return $_[0]->{max}++;
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
  $self->{deletes} = [sort @{$self->{deletes}}];
  return $self;
};


sub freq {
  my $self = shift;
  $self->{max} - scalar @{$self->{deletes}}
}

sub pointer {
  my $self = shift;
  # Krawfish::Index::PostingLivePointer->new($self);
  return $self;
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
