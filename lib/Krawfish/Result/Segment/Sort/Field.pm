package Krawfish::Result::Segment::Sort::Field;
use strict;
use warnings;

# Sorting criterion for field ranks.

# TODO:
#   Probably not only support ranks but all kinds of sorting
#   by having a get_lt() API that also works for strings!

sub new {
  my $class = shift;

  my $self = bless {
    segment    => shift,
    field      => shift,
    descending => shift // 0
  }, $class;

  # Get ranking
  # $self->{ranks} = $self->{index}->fields->ranked_by($field) or return;

  # Get maximum rank if descending order
  # $self->{max} = $self->{ranks}->max if $self->{descending};

  return $self;
};


sub get {
  my $self = shift;
#  my $max = $ranking->max if $desc;

  # Get stored rank
#  $rank = $ranking->get(shift);

  # Revert if maximum rank is set
#  return $max ? $max - $rank : $rank;
};


1;
