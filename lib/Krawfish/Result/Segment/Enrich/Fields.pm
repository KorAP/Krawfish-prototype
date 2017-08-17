package Krawfish::Result::Segment::Enrich::Fields;
use parent 'Krawfish::Result';
use Krawfish::Posting::Match::Fields;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 1;

# This will enrich each match with specific field information
# Needs to be called on the segment level

# Constructor
sub new {
  my $class = shift;
  bless {
    field_obj => shift,
    query     => shift,
    fields    => shift, # Expects to be numerical sorted field identifier
    match     => undef,
    pointer   => undef,
    last_doc_id => -1
  }, $class;
};

sub _init {
  my $self = shift;

  # Pointer is already initiated
  return if $self->{init}++;

  # Match is already set
  if (DEBUG) {
    print_log(
      'r_fields',
      'Initiate pointer to fields'
    );
  };

  $self->{pointer} = $self->{field_obj}->pointer;
  return;
};


sub pointer {
  $_[0]->{pointer};
};


# Get current match
sub current_match {
  my $self = shift;

  $self->_init;

  # Match is already set
  if ($self->{match}) {
    if (DEBUG) {
      print_log(
        'r_fields',
        'Match already defined ' . $self->{match}->to_string
      );
    };
    return $self->{match};
  };

  my $match = $self->match_from_query;


  # Match is in the same document as before
  if ($match->doc_id == $self->{last_doc_id}) {

    # Create an enrichment
    $match->add(
      Krawfish::Posting::Match::Fields->new(@{$self->{last_fields}})
      );

    # The document has no associated fields
    return ($self->{match} = $match);
  };

  # Retrieve from data

  # Get fields object
  my $fields = $self->{pointer};

  # Move to document in field stream
  my $fields_doc_id = $fields->skip_doc($match->doc_id);
  if ($fields_doc_id != $match->doc_id) {

    if (DEBUG) {
      print_log('r_fields', 'Match doc id #' . $match->doc_id .
                  ' mismatches fields doc id #' . $fields_doc_id);
    };

    # The document has no associated fields
    return ($self->{match} = $match);
  };

  # Get the fields from the fields stream
  my @fields = $fields->fields(@{$self->{fields}});

  $self->{last_doc_id} = $match->doc_id;
  $self->{last_fields} = [@fields];

  # Create an enrichment
  $match->add(
    Krawfish::Posting::Match::Fields->new(@fields)
    );

  $self->{match} = $match;

  print_log('r_fields', 'Match now contains data for ' . join(', ', @fields)) if DEBUG;

  return $match;
};


# Next match
sub next {
  my $self = shift;
  $self->{match} = undef;
  return $self->{query}->next;
};


sub to_string {
  my $str = 'enrichFields(' . join(',', @{$_[0]->{fields}}) . ':';
  $str .= $_[0]->{query}->to_string;
  return $str . ')';
};

1;
