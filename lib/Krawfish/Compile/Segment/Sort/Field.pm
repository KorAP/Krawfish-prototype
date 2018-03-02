package Krawfish::Compile::Segment::Sort::Field;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

# TODO:
#   Use this an instantiate it directly with
#   a ranking!

# Sorting criterion for field ranks.

# TODO:
#   Probably not only support ranks but all kinds of sorting
#   by having a get_lt() API that also works for strings!

# TODO:
#   Return max rank for unknown fields!

# TODO:
#   This may need to be an inflatable


sub new {
  my $class = shift;

  my ($segment, $field_id, $descending) = @_;

  # Get ranking
  my $rank = $segment->field_ranks->by($field_id);

  return unless $rank;

  my $self = bless {
    field_id => $field_id,
    rank     => $rank,
    desc     => $descending,
    max_rank => $rank->max_rank
  }, $class;

  return $self;
};

sub type {
  'field';
};


# Get the rank for this criterion
sub rank_for {
  my ($self, $doc_id) = @_;


  # Get fields in descending order
  if ($self->{desc}) {

    # This may be a real descending order file
    # or a reversed single-valued ascending order file
    return $self->{rank}->desc_rank_for($doc_id) || ($self->max_rank + 1);
  };

  # Get fields in ascending order
  return $self->{rank}->asc_rank_for($doc_id) || ($self->max_rank + 1);

  # Get rank if rank is littler than value
  # my $value = shift;
  # return $self->{rank}->rank_doc_lt($doc_id, $value);
  #  my $max = $ranking->max if $desc;
};


# Get key by rank
sub key_for {
  my ($self, $rank) = @_;

    # Get fields in descending order
  if ($self->{desc}) {

    # This may be a real descending order file
    # or a reversed single-valued ascending order file
    return $self->{rank}->desc_key_for($rank);
  };

  # Get fields in ascending order
  return $self->{rank}->asc_key_for($rank);
};


sub criterion {
  $_[0]->{field_id};
};

sub max_rank {
  $_[0]->{max_rank}
}

sub term_id {
  $_[0]->{field_id};
};


# Stringification
sub to_string {
  my $self = shift;
  return 'field=#' . $self->{field_id} . ($self->{desc} ? '>' : '<')
};

1;
