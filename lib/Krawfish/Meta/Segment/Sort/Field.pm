package Krawfish::Meta::Segment::Sort::Field;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 1;

# TODO:
#   Use this an instantiate it directly with
#   a ranking!

# Sorting criterion for field ranks.

# TODO:
#   Probably not only support ranks but all kinds of sorting
#   by having a get_lt() API that also works for strings!

# TODO:
#   Return max rank for unknown fields!

sub new {
  my $class = shift;

  my ($segment, $field_id, $descending) = @_;

  # Get ranking
  my $rank = $segment->field_ranks->by($field_id);

  return unless $rank;

  my $self = bless {
    field_id => $field_id,
    desc     => $descending,
    max_rank => $rank->max_rank
  }, $class;

  # Get fields in descending order
  if ($descending) {

    # This may be a real descending order file
    # or a reversed single-valued ascending order file
    $self->{rank} = $rank->descending or return;
  }

  # Get fields in ascending order
  else {
    $self->{rank} = $rank->ascending or return;
  };

  return $self;
};


# Get the rank for this criterion
sub rank_for {
  my ($self, $doc_id) = @_;

  return $self->{rank}->rank_for($doc_id);

  # Get rank if rank is littler than value
  # my $value = shift;
  # return $self->{rank}->rank_doc_lt($doc_id, $value);
  #  my $max = $ranking->max if $desc;
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

# TODO:
#   This may need to be an inflatable
sub to_string {
  my $self = shift;
  return 'field=#' . $self->{field_id} . ($_->{desc} ? '>' : '<')
};

1;
