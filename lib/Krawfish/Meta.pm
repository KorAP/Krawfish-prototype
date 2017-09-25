package Krawfish::Meta;
use parent 'Krawfish::Query';
use Krawfish::Koral::Result::Match;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

sub current_match {
  my $self = shift;
  my $current = $self->current;
  return unless $current;
  return Krawfish::Koral::Result::Match->new(
    doc_id  => $current->doc_id,
    start   => $current->start,
    end     => $current->end,
    payload => $current->payload
  );
};


# TODO:
#   gibt nur den current des queries zurück.
#   bei sort() wird zusätzlich das criterion
#   hinzugefügt.
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
      payload => $current->payload->clone
    );
  };

  return $match;
};


1;
