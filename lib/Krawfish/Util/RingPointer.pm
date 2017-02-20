package Krawfish::Util::RingPointer;
use strict;
use warnings;


# The ring pointer wraps around a ring buffer that
# wraps around a span stream
#
# This will probably become a query that points to a
# buffer with a signature - so multiple queries can
# point to a single buffer.

sub new {
  my $class = shift;
  my $buffer = shift;

  # Too many buffers have joint the buffer
  return unless $buffer->incr_pointer;

  bless {
    start  => 0,  # Minimum pointer value
    finger => 0,  # Current pointer value
    end    => 0,  # Maximum pointer value
    buffer => $buffer
  };
};


# Get next element
sub next {
  my $self = shift;
  my $buffer = $self->{buffer};

  # Increment current finger
  $self->{finger}++;

  # The new position is beyond the end position!
  if ($self->{finger} > $self->{end}) {

    # This will increment the reference count
    $self->{end} = $self->{finger};

    # Increment the new buffer element
    $buffer->incr_ref_count($self->{end});
  };

  # Get current element
  $self->{current} = $buffer->get($self->{finger});

  return 1 if $self->{current};
  return;
};


# Get the current element
sub current {

  # May directly point to the buffer
  # instead of copying!
  return $_[0]->{current};
};


sub rewind {
  my $self = shift;
  $self->{finger} = $self->{start};
};


sub to_end {
  my $self = shift;
  $self->{finger} = $self->{end};
};



1;
