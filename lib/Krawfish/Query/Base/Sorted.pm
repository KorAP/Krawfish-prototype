package Krawfish::Query::Base::Sorted;
use parent 'Krawfish::Query';
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

# Base query for queries that may be unsorted.

# TODO:
#   Implement using Krawfish::Util::Heap

# TODO:
#   Implement as an overwriting ring buffer (FIFO) with
#   byte precision.
#
# The recent element indicates the last freed element,
# to know, whenever a sorting fails (i.e. an element has
# an ordering earlier then the earliest element.
#
# TODO:
#   0 points to the last bubbled element. That means, if an element
#   tries to be buffered that needs to be before this element, a warning
#   should be issued, that the buffer was exceeded!

# Elements have:
# <size><data>


# Constructor
sub new {
  my $class = shift;
  bless {
    span     => shift,
    capacity => shift, # The size of the buffer, in the future given in bytes
    offset   => 0,     # The numerical offset for numbered access
    size     => 0,     # The number of elements in the buffer
    recent   => 0,     # Pointer to the last freed element in the buffer
    first    => 0,     # Pointer to the first  element in the buffer
    last     => 0,     # Pointer to the last element in the buffer
    buffer   => []     # Array holding all elements in the buffer
  }, $class;
};


# Move to next sorted posting
sub next {
  my $self = shift;

  while ($self->{span}->next) {
    my $next_post = $self->{span}->current;

    # Sort buffer
    my $last_index = $self->buffer_last;

    print_log('sortbuf', "Last position in buffer is $last_index") if DEBUG;

    my $buffer_post = $self->buffer_get($last_index);

    if (DEBUG) {
      print_log(
        'sortbuf',
        'Last buffer element is ' . ($buffer_post ? '' : 'not') . ' given'
      );
    };

    # Compare next posting with last element in buffer
    while ($next_post->compare($buffer_post) == -1) {
      $last_index--;

      if ($last_index == 0) {
        # todo! Add at beginning!
        ...
      };

      # Get last buffer post
      $buffer_post = $self->buffer_get($last_index);
    };

    # Insert posting at the correct position in the buffered stream
    $self->buffer_insert_after($last_index, $next_post);

    # The buffer has reached its limit
    if ($self->buffer_length >= $self->capacity) {
      return $self->buffer_shift;
    };
  };

  return $self->buffer_shift;
};


# Return index to last added element
sub buffer_last {
  ...
};


# Points to the latest freed element in the buffer
# (normally this is -1 to first)
sub buffer_recent {
  return $_[0]->{recent};
};


# Points to the first accessible element in the buffer
sub buffer_first {
  return $_[0]->{first};
};


sub buffer_shift {
  ...
};


sub buffer_get {
  ...
};


sub buffer_insert_after {
  my ($self, $index, $element) = @_;
};


1;
