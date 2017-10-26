package Krawfish::Compile;
use parent 'Krawfish::Query';
use Krawfish::Koral::Result::Match;
use Krawfish::Koral::Result;
use Krawfish::Log;
use strict;
use warnings;

# Krawfish::Compile is the base class for all Compile queries.


use constant DEBUG => 0;


# Return match object
sub current_match {
  my $self = shift;
  my $current = $self->current;
  return unless $current;
  return Krawfish::Koral::Result::Match->new(
    doc_id  => $current->doc_id,
    start   => $current->start,
    end     => $current->end,
    payload => $current->payload,
    flags   => $current->flags
  );
};


# Return the current posting
sub current {
  shift->{query}->current;
};


# Based on the current query this returns either
# a predefined match (when nesting) or creates a match
# based on the query
# May simply be the method
# current_match() in Krawfish::Query!
sub match_from_query {
  my $self = shift;

  print_log('result', 'Get match from query') if DEBUG;

  # Get current match from query
  my $match = $self->{query}->current_match;

  # Not yet defined
  unless ($match) {

    print_log('result', 'No match found yet') if DEBUG;

    # Get current object
    my $current = $self->current;

    print_log('result', 'Current posting is '. $self->{query}->to_string) if DEBUG;

    # Create new match
    $match = Krawfish::Koral::Result::Match->new(
      doc_id  => $current->doc_id,
      start   => $current->start,
      end     => $current->end,
      flags   => $current->flags,
      payload => $current->payload->clone
    );
  };

  return $match;
};


# Get maximum frequency
sub max_freq {
  $_[0]->{query}->max_freq;
};


# Override to compile data
sub compile {
  $_[0];
};


# Get result object
sub result {
  my $self = shift;
  if ($_[0]) {
    $self->{result} = shift;
    return $self;
  };
  $self->{result} //= Krawfish::Koral::Result->new;
  return $self->{result};
};


1;
