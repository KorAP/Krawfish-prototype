package Krawfish::Query::Constraint::InSpanDistance;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless {
    span => shift,
    buffer => shift,
    min => shift,
    max => shift
  }, $class;
}

sub check {
  my $self = shift;
  my ($payload, $first, $second) = @_;

  # TODO: init span

  my $span = $self->{span};

  my $buffer = $self->{buffer};

  # No current element
  return 0b0000 unless $span->current;

  # Move span to correct position
  while ($span->current->doc_id < $first->doc_id) {
    $span->next or return NEXTA | NEXTB;
  };

  my $current = $span->current or return 0b0000;

  my ($start, $end) = $first->start < $second->start ? ($first, $second) : ($second, $first);
  
  if ($first->end > $current->end)
};

1;
