package Krawfish::Result::Segment::Fields;
use parent 'Krawfish::Result';
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

# This will enrich each match with specific field information
# Needs to be called on the segment level

# Constructor
sub new {
  my $class = shift;
  bless {
    index => shift,
    query => shift,
    fields => shift,
    match => undef
  }, $class;
};


# Get current match
sub current_match {
  my $self = shift;

  # Match is already set
  if ($self->{match}) {
    if (DEBUG) {
      print_log(
        'c_fields',
        'Match already defined ' . $self->{match}->to_string
      );
    };
    return $self->{match};
  };

  my $match = $self->match_from_query;

  # Get fields object
  my $fields = $self->{index}->fields;

  # Retrieve field data of the document
  my $data = $fields->get($match->doc_id);

  # Filter fields!
  if ($self->{fields}) {

    my %fields;
    foreach (@{$self->{fields}}) {
      $fields{$_} = $data->{$_} if $data->{$_};
    };

    # Add data to match
    $match->fields(\%fields);
  }
  else {
    $match->fields($data);
  };

  $self->{match} = $match;

  print_log('c_fields', 'Match now contains data for ' . join(', ', keys %$data)) if DEBUG;

  return $match;
};


# Next match
sub next {
  my $self = shift;
  $self->{match} = undef;
  return $self->{query}->next;
};


1;
