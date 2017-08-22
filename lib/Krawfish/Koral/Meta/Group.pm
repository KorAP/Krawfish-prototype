package Krawfish::Koral::Meta::Group;
use strict;
use warnings;


sub new {
  my $class = shift;
  bless {
    criterion => shift
  }, $class;
};


sub criterion {
  $_[0]->{criterion};
};

sub type {
  'group';
};


# TODO:
#   wrap one group type into another!
#
sub wrap {
  my ($self, $query) = @_;

  # Group by
  return $self->criterion->wrap($query);
};


# Normalize aggregations
sub normalize {
  $_[0];
};


sub to_string {
  my $self = shift;
  return 'group=[' . $self->criterion->to_string . ']';
};

1;
