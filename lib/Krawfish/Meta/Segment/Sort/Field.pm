package Krawfish::Meta::Segment::Sort::Field;
use strict;
use warnings;

# Sorting criterion for field ranks.

# TODO:
#   Probably not only support ranks but all kinds of sorting
#   by having a get_lt() API that also works for strings!

sub new {
  my $class = shift;

  my ($segment, $field_id, $descending) = @_;

  my $self = bless {
    field_id   => $field_id
  }, $class;

  # Get ranking
  my $rank = $segment->field_ranks;

  # Get fields in descending order
  if ($self->{descending}) {

    # This may be a real descending order file
    # or a reversed single-valued ascending order file
    $self->{rank} = $rank->descending($field_id);
  }

  # Get fields in ascending order
  else {
    $self->{rank} = $rank->ascending($field_id);
  };

  # $self->{ranks} = $self->{index}->fields->ranked_by($field) or return;
  # Get maximum rank if descending order
  # $self->{max} = $self->{ranks}->max if $self->{descending};

  return $self;
};


sub get {
  my ($self, $doc_id, $value) = @_;

  if ($value) {
    return $self->{rank}->rank_doc($doc_id);
  };

  # Get rank if rank is littler than value
  return $self->{rank}->rank_doc_lt($doc_id, $value);
  #  my $max = $ranking->max if $desc;

  # Get stored rank
  #  $rank = $ranking->get(shift);

  # Revert if maximum rank is set
  #  return $max ? $max - $rank : $rank;
};


sub criterion {
  $_[0]->{field_id};
};


1;
