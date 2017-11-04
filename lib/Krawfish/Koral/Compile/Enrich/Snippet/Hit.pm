package Krawfish::Koral::Compile::Enrich::Snippet::Hit;
use Krawfish::Compile::Segment::Enrich::Snippet::Hit;
use strict;
use warnings;

# Define the hit object
# (e.g. which annotations should occur)

sub new {
  my $class = shift;

  warn 'DEPRECATED!';

  bless { @_ }, $class;
};

sub identify {
  $_[0];
};

sub optimize {
  my $self = shift;
  Krawfish::Compile::Segment::Enrich::Snippet::Hit->new(
    %$self
  );
};

sub to_string {
  return 'hit';
};

1;
