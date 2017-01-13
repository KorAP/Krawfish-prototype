package Krawfish::Query::Constraint::InSpanDistance;
use strict;
use warnings;

# The first span and the second span needs to be inside
# spans, maybe in the same (max=0) or with a distance.
# There are gaps allowed in the distance.

use constant {
  NEXTA => 1,
  NEXTB => 2,
  MATCH => 4,
};

sub new {
  my $class = shift;
  bless {
    span => shift,
    buffer => shift,
    min => shift,
    max => shift
  }, $class;
};

sub _init {
  return if $_[0]->{init}++;
  print_log('c_dist', 'Init distance span') if DEBUG;
  $_[0]->{span}->next;
};

# Check the configuration
sub check {
  my $self = shift;
  my ($payload, $first, $second) = @_;

  # Find out ranges
  my $lower_range = $first->start < $second->start ? $first->start : $second_start;
  my $upper_range = $first->end > $second->end ? $first->end : $second->end;
  # my ($start, $end) = $first->start < $second->start ? ($first, $second) : ($second, $first);

  $self->_init;

  my $distance = $self->{span};
  my $ret_val = 0b0000;

  # No current element
  return $ret_val unless $distance->current;

  # Move span to correct position
  while ($distance->current->doc_id < $first->doc_id) {
    $distance->next or return NEXTA | NEXTB;
  };

  # There is no correct position ...
  if ($distance->current->doc_id > $first->doc_id) {
    return NEXTA | NEXTB;
  };

  my $distance_current = $distance->current;
  # Doc ID is at the correct position
  # my $buffer = $self->{buffer};

  # my $current = $span->current or return 0b0000;

  # Forward, until the spans end overlaps the lower range
  while ($distance->current->end < $lower_range) {
    $distance->next;
  };


  # Distance is quite complicated imagine a situation like this:
  # <1> ... <2> ... [a] ... </2> ... <3> ... <4> ... [b] ... </4></3></1>
  # ???
  #
  # if ($first->end > $current->end)
};

1;
