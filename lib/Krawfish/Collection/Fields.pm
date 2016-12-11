package Krawfish::Collection::Fields;
use parent 'Krawfish::Collection';
use Krawfish::Log;
use Krawfish::Posting::Match;
use strict;
use warnings;

use constant DEBUG => 0;

sub new {
  my $class = shift;
  bless {
    query => shift,
    index => shift,
    fields => shift
  }, $class;
};

sub current_match {
  my $self = shift;

  # Match is already set
  return $self->{match} if $self->{match};

  # Get current match from query
  my $match = $self->{query}->current_match;

  print_log('c_fields', 'Fetch fields for current document') if DEBUG;

  # Not yet defined
  unless ($match) {

    # Get current object
    my $current = $self->{query}->current;

    print_log('c_fields', 'Query has no current match for document ' . $current->doc_id) if DEBUG;

    # Create new match
    $match = Krawfish::Posting::Match->new(
      doc_id => $current->doc_id,
      start => $current->start,
      end => $current->end,
      payload => $current->payload->clone
    );
  };

  # Get fields object
  my $fields = $self->{index}->fields;

  # Retrieve field data of the document
  my $data = $fields->get($match->doc_id);

  # TODO:
  #   Filter fields!

  # Add data to match
  $match->fields($data);

  $self->{match} = $match;

  print_log('c_fields', 'Match now contains data for ' . join(', ', keys %$data)) if DEBUG;

  return $match;
};

sub next {
  my $self = shift;
  $self->{match} = undef;
  return $self->{query}->next;
};

1;
