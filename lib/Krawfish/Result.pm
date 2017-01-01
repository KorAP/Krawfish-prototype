package Krawfish::Result;
use parent 'Krawfish::Query';
use Krawfish::Posting::Match;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

sub current_match {
  my $self = shift;
  return unless defined $self->{doc_id};
  return Krawfish::Posting::Match->new(
    doc_id  => $self->{doc_id},
    start   => $self->{start},
    end     => $self->{end},
    payload => $self->{payload}
  );
};


sub match_from_query {
  my $self = shift;

  print_log('c_collect', 'Get match from query') if DEBUG;

  # Get current match from query
  my $match = $self->{query}->current_match;

  # Not yet defined
  unless ($match) {

    print_log('c_collect', 'No match found yet') if DEBUG;

    # Get current object
    my $current = $self->{query}->current;

    print_log('c_collect', 'Current posting is '. $self->{query}->to_string) if DEBUG;

    # Create new match
    $match = Krawfish::Posting::Match->new(
      doc_id  => $current->doc_id,
      start   => $current->start,
      end     => $current->end,
      payload => $current->payload->clone
    );
  };

  return $match;
};


1;
