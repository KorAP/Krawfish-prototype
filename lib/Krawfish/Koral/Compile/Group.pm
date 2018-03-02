package Krawfish::Koral::Compile::Group;
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


# Type is group
sub type {
  'group';
};


# TODO:
#   wrap one group type into another!
#
sub wrap {
  my ($self, $query) = @_;

  # Group by
  my $wrap = $self->criterion->wrap($query);
};


# Normalize group
sub normalize {
  $_[0];
};


# Stringification
sub to_string {
  my $self = shift;
  return 'group=[' . $self->criterion->to_string . ']';
};


1;
