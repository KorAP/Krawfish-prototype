package Krawfish::Koral::Result::Match;
use strict;
use warnings;

# TODO:
#   This may be embedded in documents!

sub new {
  my $class = shift;
  my $self = bless {
    @_
  }, $class;
};

1;
