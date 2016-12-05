package Krawfish::Index::PostingsLive;
use strict;
use warnings;

# TODO: Has a "delete" method and works otherwise identical to PostingsList and PostingPointer

sub new {
  my ($class, $index_file, $max) = @_;
  bless {
    index_file => $index_file,
    deletes => [],
    pointers => [],
    max => $max # Maximum number of documents
  }, $class;
};

sub delete {
  my $self = shift;
  push @{$self->{deletes}}, shift;
  $self->{deletes} = [sort @{$self->{deletes}}];
};

sub freq {
  $_[0]->{max} - scalar @{$self->{deletes}}
}

sub pointer {
  Krawfish::Index::PostingLivePointer->new($self);
};

sub to_string {
  '...'
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
