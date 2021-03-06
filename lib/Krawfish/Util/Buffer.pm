package Krawfish::Util::Buffer;
use Krawfish::Log;
use Carp qw/carp/;
use bytes;
use strict;
use warnings;

# Buffer contains a queue of spans, with a finger to point
# on certain positions in the queue

# TODO:
#   See for an example implementation listpack.c (redis):
#   - https://gist.github.com/antirez/66ffab20190ece8a7485bd9accfbc175


# TODO:
#   Make this a Buffered Query, so it can have a simplified API
#   For usage, with next (that may either use the buffer or the
#   nested stream.
#
#   It may probably need
#   ->rewind
#   ->forget

use constant DEBUG => 0;

# Constructor
sub new {
  bless {
    finger => 0,
    array => []
  }, shift;
};


# Go to the next element of the buffer
sub next {
  my $self = shift;
  print_log('buffer', "Try to forward buffer finger: " . $self->to_string) if DEBUG;
  # print_log('buffer', "Finger: " . $self->finger . ' of ' . $self->size) if DEBUG;

  $self->{finger}++;

  if ($self->{finger} >= $self->size) {
    print_log('buffer', 'Finger is already at the end of the buffer') if DEBUG;
    return;
  };

  print_log('buffer', 'Forward buffer finger: ' . $self->to_string) if DEBUG;
  return 1;
};


# Return the current element of the buffer
sub current {
  my $self = shift;
  return if $self->{finger} >= $self->size;
  return $self->{array}->[$self->{finger}];
};


# Return the current position of the finger
# Or set the finger
sub finger {
  if (defined $_[1]) {
    $_[0]->{finger} = $_[1];
    print_log('buffer', "Set finger to $_[1]: " . $_[0]->to_string) if DEBUG;
  }
  $_[0]->{finger};
};


#sub forward {
#  $_[0]->{finger}++;
#  print_log('buffer', 'Move finger forward') if DEBUG;
#};


sub backward {
  $_[0]->{finger}--;
  print_log('buffer', 'Move finger backwards') if DEBUG;
};


# Remember item
sub remember {
  my $self = shift;
  my $span = shift;
  print_log('buffer', "Remember $span in buffer: " . $self->to_string) if DEBUG;
  push @{$self->{array}}, $span;
  return 1;
};

sub first {
  $_[0]->{array}->[0];
};


# Reset finger to start position
sub rewind {
  $_[0]->{finger} = 0;
  print_log('buffer', 'Reset buffer finger: ' . $_[0]->to_string) if DEBUG;
};


# Position finger to last element
sub to_end {
  my $self = shift;
  $self->{finger} = $self->size - 1;
};


# Check size
sub size {
  return scalar @{$_[0]->{array}};
};


# Forget first element and reposition finger
sub forget {
  my $span = shift(@{$_[0]->{array}});

  unless ($span) {
    carp 'Nothing to forget';
    return;
  };

  print_log('buffer', "Forget span $span: " . $_[0]->to_string) if DEBUG;

  # decrement finger
  $_[0]->{finger}--;

  print_log('buffer', "Buffer is now " . $_[0]->to_string) if DEBUG;
  return 1;
};


# Clear buffer
sub clear {
  print_log('buffer', 'Clear buffer list') if DEBUG;
  $_[0]->{array} = [];
  $_[0]->{finger} = 0;
};


# Stringify buffer content
sub to_string {
  my $self = shift;
  my $string = '';
  my $finger = $self->{finger};
  foreach (0 .. $finger-1) {
    $string .= ($self->{array}->[$_] // '');
  };
  $string .= ' <';
  $string .= $self->{array}->[$finger] // '';
  $string .= '> ';

  foreach ($finger + 1 .. ($self->size - 1)) {
    $string .= ($self->{array}->[$_] // '');
  };

  return $string;
};

1;
