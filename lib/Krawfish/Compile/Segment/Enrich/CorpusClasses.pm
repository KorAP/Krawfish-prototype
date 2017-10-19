package Krawfish::Compile::Segment::Enrich::CorpusClasses;
use parent 'Krawfish::Compile';
use strict;
use warnings;

# This is not in use currently

# Move to next item
sub next {
  $_[0]->{query}->next;
};


# Get current match
sub current_match {
  my $self = shift;

  my $match = $self->current_match or return;

  # Get classes - ignore first
  my @classes = $match->flags_list(0b0111_1111_1111_1111);

  # Enrich match
  $match->add(
    Krawfish::Koral::Result::Enrich::CorpusClasses->new(@classes)
    );

  return $match;
};


# Stringification
sub to_string {
  'corpusClasses(' . join(',', $_[0]->{query}) . ')'
};

1;
