package Krawfish::Meta::Segment::Sort::SubTerm;
use strict;
use warnings;

# This will sort based on a pre-ranked subterm

sub new {
  my $class = shift;

  my $self = bless {
    index => shift,
    suffix => shift // 0,
    descending => shift // 0,
  }, $class;

  # Get ranking
  $self->{dict} = $self->{index}->dictionary or return;

  # Get maximum rank if descending order
  $self->{max} = $self->{ranks}->max if $self->{descending};

  return $self;
};

sub get {
  my $self = shift;
  my $subterm_id = shift;
  my $rank;
  if ($self->{suffix}) {
    $rank = $self->{dict}->prefix_rank_by_subterm_id($subterm_id);
  }
  else {
    $rank = $self->{dict}->suffix_rank_by_subterm_id($subterm_id);
  };

  # Revert if maximum rank is set
  return $max ? $max - $rank : $rank;
};


1;
