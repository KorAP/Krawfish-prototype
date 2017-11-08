package Krawfish::Compile::Segment::Enrich::CorpusClasses;
use Krawfish::Koral::Result::Enrich::CorpusClasses;
use strict;
use warnings;
use Role::Tiny;

with 'Krawfish::Compile';


# Constructor
sub new {
  my $class = shift;
  return bless { @_ }, $class;
};


# Move to next item
sub next {
  $_[0]->{query}->next;
};


# Get current match
sub current_match {
  my $self = shift;

  my $match = $self->match_from_query or return;

  # Get classes - ignore first
  my @classes = $match->corpus_classes(0b0111_1111_1111_1111);

  # Enrich match
  $match->add(
    Krawfish::Koral::Result::Enrich::CorpusClasses->new(@classes)
    );

  return $match;
};


# Stringification
sub to_string {
  'corpusClasses(' . $_[0]->{flags} . ':' . $_[0]->{query}->to_string . ')'
};

1;
