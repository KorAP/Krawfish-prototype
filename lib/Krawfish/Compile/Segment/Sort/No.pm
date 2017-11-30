package Krawfish::Compile::Segment::Sort::No;
use strict;
use warnings;

# This is a dummy sorting criterion that is
# used for fields that are either not sortable
# or for fields not in the dictionary.
# As the first may be an indication for an error
# in the index design,

sub new {
  my $class = shift;
  return bless {
    field   => shift,
    desc    => shift
  }, $class;
};


# Get the rank for this criterion
sub rank_for {
  return 0;
};


sub type {
  'no';
};

sub criterion {
  $_[0]->{field};
};

sub max_rank {
  0;
};

sub key_for {
  undef;
};

sub to_string {
  my $self = shift;
  return 'field=' . $self->{field} . ($_->{desc} ? '>' : '<')
};

1;
