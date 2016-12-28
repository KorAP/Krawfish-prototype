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

  my $match = $self->match_from_query;

  # Get fields object
  my $fields = $self->{index}->fields;

  # Retrieve field data of the document
  my $data = $fields->get($match->doc_id);

  #   Filter fields!
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

sub next {
  my $self = shift;
  $self->{match} = undef;
  return $self->{query}->next;
};

1;
