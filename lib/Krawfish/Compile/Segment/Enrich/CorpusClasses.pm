package Krawfish::Compile::Segment::Enrich::CorpusClasses;
use Krawfish::Koral::Result::Enrich::CorpusClasses;
use Krawfish::Log;
use strict;
use warnings;
use Role::Tiny::With;

with 'Krawfish::Compile::Segment';

# TODO: Support flags

use constant DEBUG => 0;

# Constructor
sub new {
  my $class = shift;
  return bless { @_ }, $class;
};


# Move to next item
sub next {
  $_[0]->{match} = undef;
  $_[0]->{query}->next;
};


# Clone query
sub clone {
  return __PACKAGE__->new(
    query => $_[0]->{query}->clone,
    flags => $_[0]->{flags}
  );
};


# Get current match
sub current_match {
  my $self = shift;

  if (DEBUG) {
    print_log('e_cclasses', 'Get current match');
  };

  return $self->{match} if $self->{match};

  my $match = $self->match_from_query or return;

  # Get classes - ignore first
  my @classes = $match->corpus_classes(0b0111_1111_1111_1111);

  # Enrich match
  if (@classes) {
    $match->add(
      Krawfish::Koral::Result::Enrich::CorpusClasses->new(@classes)
      );
  };

  if (DEBUG) {
    print_log('e_cclasses', 'Current match is ' . $match->to_string);
  };

  $self->{match} = $match;

  return $match;
};


# Stringification
sub to_string {
  'eCorpusClasses(' . $_[0]->{flags} . ':' . $_[0]->{query}->to_string . ')'
};

1;
