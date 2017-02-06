package Krawfish::Query::Util::RingBuffer;
use strict;
use warnings;

# TODO:
#   - Implement this as a ring buffer, with a read, a write, and a start
#     pointer
#     https://en.wikipedia.org/wiki/Circular_buffer
#   - For reference queries, multiple start and current pointers
#     may be needed,
#     or the start pointer needs to be forwarded manually based
#     on external bookkeeping
#     In addition an absolute start value may be needed, that can
#     be moved forward (and be overwritte) the moment all
#     start pointers are > abs_start
#     This may be done with a reference counter per element
#     (meaning if abs_start is null, abs_start can be removed).
#
#     Buffer: <start><end/capacity>
#     BufferPointer: <start><current>
#     Ring-Elements: <refcount(8bits for 255 pointers)><length><elem>
#
#     If a next() points to the end of the buffer, a new element
#     is retrieved from the real stream.
#
#     Possibly make it possible to enlarge the buffer size, when it
#     (rarely) is to small. This should occur only in rare circumstances!


# Maximum number of pointers that can join the buffer
use constant MAX_POINTER => 255;

# start needs to be a reference value!

sub new {
  my $class = shift;
  bless {
    capacity => shift,
    span => shift,
    pointer => 0,
    start => 0,
    end => 0,
    elements => []
  }, $class;
};


# Increment reference counter for an element
sub incr_ref_count {
  my ($self, $finger) = @_;

  # Move forward!
  if ($finger > $self->{end}) {

    # Get next element from buffer
    if ($self->{span}->next) {

      # Remember the current span
      $self->remember($self->{span}->current);
      return 1;
    };

    # No more elements
    return;
  }

  # Just increment the reference
  else {
    $self->{elements}->[$finger]->[0]++;
  };
};


# Decrement the reference counter
sub decr_ref_count {
  my ($self, $finger) = @_;

  # Increment the reference count
  $self->{elements}->[$finger]->[0]--;

  # The reference count of the element is null
  # - can now be forgotten
  unless ($self->{elements}->[$finger]) {
    $self->forget;
  };
};


# Increment pointer
sub incr_pointer {
  $_[0]->{pointer}++;
  if ($_[0]->{pointer} > MAX_POINTER) {
    return 0;
  };
  return 1;
};

sub get {
  my ($self, $finger) = @_;
  return $self->{elements}->[$finger];
};


# Remember element in buffer
# TODO:
#   Deal with ring
sub remember {
  my ($self, $element) = @_;
  $self->{end}++;
  $self->{elements}->[$self->{end}] = [1, $element];
};


# Forget element in buffer
# TODO:
#   Deal with ring
sub forget {
  $_[0]->{start}++;
};


# Return span element
sub span {
  $_[0]->{span};
};

sub to_string;

# sub size;
# sub clear;

1;
