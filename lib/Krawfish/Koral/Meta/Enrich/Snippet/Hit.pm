package Krawfish::Koral::Meta::Enrich::Snippet::Hit;
use Krawfish::Meta::Segment::Enrich::Snippet::Hit;
use strict;
use warnings;

# Define the hit object
# (e.g. which annotations should occur)

sub new {
  my $class = shift;
  bless { @_ }, $class;
};

sub identify {
  $_[0];
};

sub optimize {
  my $self = shift;
  Krawfish::Meta::Segment::Enrich::Snippet::Hit->new(
    %$self
  );
};

sub to_string {
  return 'hit';
};

1;
