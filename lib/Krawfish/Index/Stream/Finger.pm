package Krawfish::Index::Stream::Finger;
use strict;
use warnings;

# New stream finger
sub new {
  my $class = shift;
  bless {
    stream => shift,
    offset => 0,
    delta => [], # Delta store
    current => []
  }, $class;
};

# Forward in posting stream
sub next {
  my $self = shift;
  if (my $data = $self->{stream}->get($self)) {
    $self->{current} = $data;
    return 1;
  };
  return 0;
};


sub skip_to;

sub next_pos;

sub next_doc;

# Get the current posting object
sub current {
  my $self = shift;
  return $self->{stream}->posting(@{$self->{current}});
};


# The current finger position (byte offset in the stream)
sub offset {
  if (defined $_[1]) {
    $_[0]->{offset} = $_[1];
  };
  return $_[0]->{offset};
};


# Delta store
sub delta {
  $_[0]->{delta};
};

1;
