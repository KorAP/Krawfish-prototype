package Krawfish::Result::Segment::Enrich::Context;
use parent 'Krawfish::Result';
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 1;


# DEPRECATED!!!


# This will add context (only surface forms) to each match

# TODO:
#   Context always needs to be left AND right, because
#   at least the surrounding elements context will expand
#   both sides at the same time!


sub new {
  my $class = shift;
  bless {
    forward_obj => shift,
    query => shift,

    # TODO:
    #   Should support
    #   - surrounding elements
    #   - left elements / right elements
    #   - left tokens / right tokens
    #   - left characters / right characters
    contextualize  => shift, # Accept context object
    match => undef
  }, $class;
};

# Initialize forward counter
sub _init {
  return if $_[0]->{forward_pointer};

  my $self = shift;

  print_log('e_context', 'Create forward pointer') if DEBUG;

  # Load the ranked list - may be too large for memory!
  $self->{forward_pointer} = $self->{forward_obj}->pointer;
};


sub current_match {
  my $self = shift;

  $self->_init;

  # Match is already set
  if ($self->{match}) {
    if (DEBUG) {
      print_log(
        'e_context',
        'Match already defined ' . $self->{match}->to_string
      );
    };
    return $self->{match};
  };

  # TODO:
  #   may simply be $self->{query}->current_match
  my $match = $self->match_from_query;

  # Get forward pointer
  my $forward = $self->{forward_pointer};

  my $doc_id = $match->doc_id;

  unless ($forward->skip_doc($doc_id) == $doc_id) {

    # TODO: This should never happen!
    return;
  };

  # Get the context
  # TODO:
  #   This may be retrieved as part of the snippet!
  my $left_context = $self->{contextualize}->left_context($match, $forward);
  my $right_context = $self->{contextualize}->right_context($match, $forward);

  # Add context to match
  $match->add(
    Krawfish::Posting::Match::Context->new(
      left => $left_context,
      right => $right_context
    ));

  return $match;
};


# Next match
sub next {
  my $self = shift;
  $self->{match} = undef;
  return $self->{query}->next;
};


sub to_string {
  my $str = 'enrichContext(' . $self->{contextualize}->to_string . ':';
  $str .= $_[0]->{query}->to_string;
  return $str . ')';
};

1;
