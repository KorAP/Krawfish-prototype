package Krawfish::Index::Postings::Buffer;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless {
    term_id     => shift,
    start       => shift,
    length      => shift,
    buffer_size => shift,
    slices      => [],
    pointers    => []
  }, $class;
};

sub term_id {
  $_[0]->{term_id};
}

# Return the frequency of the term
sub freq {
  $_[0]->{freq};
};

sub to_string {
  '#' . $_[0]->term_id;
};


# Initialize a pointer to the structure
sub pointer {
  ...
};

# Return data from the buffer
sub at {
  # If the pointer position exceeds the
  # latest slice, add the next slice.
  #   if the pointer was the earliest
  #   pointer and no more pointers point
  #   to the former slice, forget about
  #   these slices and remove them
  #   from memory
  #
  # If no more slices are available,
  # return undef
  #
  # slices have the structure
  # [start, length, binary-data]
  # start starts at 0 per postings list
  ...
};

sub remove_pointer {
  # When a pointer is closed, remove
  # it from the list.
  # If the pointer was the earliest pointer
  # probably remove the first slices from
  # the list
  ...
};

# Remove all slices from memory
sub close {
  ...
};

1;
