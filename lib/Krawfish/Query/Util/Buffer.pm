package Krawfish::Query::Util::Buffer;
use strict;
use warnings;

# Buffer contains a queue of spans, with a finger to point
# on certain positions in the queue

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
  print "  >> Try to forward buffer finger: " . $self->to_string . "\n";
  print "  >> Finger: " . $self->finger . ' of ' . $self->size . "\n";

  $self->{finger}++;

  if ($self->{finger} >= $self->size) {
    print "  >> Finger is already at the end of the buffer\n";
    return;
  };

  print "  >> Forward buffer finger: " . $self->to_string . "\n";
  return 1;
};


# Return the current element of the buffer
sub current {
  my $self = shift;
  return if $self->{finger} > $self->size;
  return $self->{array}->[$self->{finger}];
};


# Return the current position of the finger
sub finger {
  $_[0]->{finger};
};

sub forward {
  $_[0]->{finger}++;
};

# Remember item
sub remember {
  my $self = shift;
  my $span = shift;
  push @{$self->{array}}, $span;
  print "  >> Remember $span in buffer: " . $self->to_string . "\n";
};

sub first {
  $_[0]->{array}->[0];
};

sub last {
  $_[0]->{array}->[-1];
};

# Reset finger to start position
sub to_start {
  $_[0]->{finger} = 0;
  print "  >> Reset buffer finger: " . $_[0]->to_string . "\n";
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
  print "  >> Forget span $span: " . $_[0]->to_string . "\n";
  $_[0]->{finger}-- if $span;
  print "  >> Buffer is now " . $_[0]->to_string . "\n";
  return 1;
};

sub clear {
  print "  >> Clear buffer list\n";
  $_[0]->{array} = [];
  $_[0]->{finger} = 0;
};


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

  foreach ($finger + 1 .. $self->size) {
    $string .= ($self->{array}->[$_] // '');
  };

  return $string;
};

1;
