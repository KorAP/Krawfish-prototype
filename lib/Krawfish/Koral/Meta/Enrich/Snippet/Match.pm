package Krawfish::Koral::Meta::Enrich::Snippet::Match;
use strict;
use warnings;

# Define the match object
# (e.g. which annotations should occur)

sub new {
  my $class = shift;
  bless { @_ }, $class;
};

sub identify {
  $_[0];
};

sub to_string {
  return 'match';
};

1;
