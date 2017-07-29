package Krawfish::Util::Heap;
use strict;
use warnings;

# Heap structure for top-k heap sort

# TODO:
#   Use this as the base for PrioritySort


sub new {
  my $class = shift;
  bless {
    top_k => shift,
    _sort => sub { $_[0] cmp $_[1] }
  }, $class;
};


# Get or set sort method
sub sort_by {
  my $self = shift;
  if (@_) {
    $self->{_sort} = shift;
    return $self;
  };
  return $self->{_sort};
};


sub enqueue {
  ...
};


sub dequeue {
  ...
};


1;
