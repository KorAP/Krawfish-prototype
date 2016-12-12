package Krawfish::Collection::Snippet::Highlights;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless {
    highlights => shift,
    segments => shift,
    stack => []
  }, $class;
};


sub clear {
  ...
};

sub parse {
  my $self = shift;

  my $current = shift;

  # Collect offsets
#  my $start_seg = $segments->get($match->doc_id, $match->start);
 # my $end_seg   = $segments->get($match->doc_id, $match->end - 1);

 # $self->add_open(0, $start_seg->[0]);
 # $self->add_close(0, $end_seg->[1]);
};

sub add_open {
  my $self = shift;
  my ($nr, $start) = @_;

  # $self->{stack} =

  # balanceStack.push(number)
};


sub add_close {
  my $self = shift;
  my ($nr, $end) = @_;
};

1;
