package Krawfish::Query::Base::Sorted;
use parent 'Krawfish::Query';
use strict;
use warnings;

# Implement as ring buffer (for cache locality in
# opposite to double linked list).
#
# TODO:
#   0 points to the last bubbled element. That means, if an element
#   tries to be buffered that needs to be before this element, a warning
#   should be issued, that the buffer was exceeded!

sub new {
  my $class = shift;
  bless {
    span => shift,
    capacity => shift,
    size => 0,
    last => 0,
    buffer => []
  }, $class;
};


# Next sorted element
sub next {
  my $self = shift;

  while ($self->{span}->next) {
    my $next_post = $self->{span}->current;

    # Sort buffer
    my $last_index = $self->buffer_last;
    my $buffer_post = $self->buffer_get($last_index);

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
};

sub buffer_push;
sub buffer_shift;
sub buffer_get;
sub buffer_insert_after;

1;
