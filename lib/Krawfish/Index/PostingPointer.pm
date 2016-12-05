package Krawfish::Index::PostingPointer;
use Krawfish::Posting;
use strict;
use warnings;

# TODO: Use Stream::Finger instead of PostingPointer

# Points to a position in a postings list

# TODO: Return different posting types
#       Using current

sub new {
  my $class = shift;
  my $self = bless {
    list => shift,
    pos => -1
  }, $class;
  $self->{freq} = $self->{list}->freq;
  return $self;
};

sub freq {
  $_[0]->{freq};
};

sub term {
  $_[0]->{list}->term;
};

sub next {
  my $self = shift;
  my $pos = $self->{pos}++;
  return ($pos + 1) < $self->freq ? 1 : 0;
};

sub next_pos;

sub next_doc;

sub pos {
  return $_[0]->{pos};
};

sub current {
  my $self = shift;
  $self->{list}->at($self->pos);
};

sub list {
  $_[0]->{list};
};

sub close {
  ...
};


# sub skip_doc_to;
# sub skip_pos_to;


1;
