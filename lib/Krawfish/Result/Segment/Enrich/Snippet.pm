package Krawfish::Result::Segment::Enrich::Snippet;
use parent 'Krawfish::Result';
use Krawfish::Koral::Result::Enrich::Snippet;
# use Krawfish::Result::Segment::Enrich::Snippet::Highlights;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 1;

# TODO:
#   It may be more efficient to first collect all required
#   annotations (for decoration, context, hit etc.) and
#   then iterate over left context, hit, right context
#   and get all annotations per token at a time


sub new {
  my $class = shift;
  # query
  # fwd_obj
  # left
  # right
  # hit
  return bless { @_ }, $class;
};


# Initialize forward index
sub _init {
  return if $_[0]->{_init}++;

  my $self = shift;
  $self->{fwd_pointer} = $self->{fwd_obj}->pointer;
};


# Iterated through the ordered matches
sub next {
  my $self = shift;
  $self->_init;
  $self->{match} = undef;
  return $self->{query}->next;
};


# Return the current match
sub current_match {
  my $self = shift;

  print_log('c_snippet', 'Get current match') if DEBUG;

  # Match is already set
  return $self->{match} if $self->{match};

  # Get current match from query
  my $match = $self->match_from_query;

  print_log('c_snippet', 'match is ' . $match) if DEBUG;

  # Get forward query
  my $forward = $self->{fwd_pointer};

  # TODO:
  #   Fetch preceding context

  my $doc_id = $match->doc_id;
  unless ($forward->skip_doc($doc_id) == $doc_id) {

    # TODO: This should never happen!
    return;
  };

  if (DEBUG) {
    print_log('c_snippet', 'Move to match doc position');
  };


  # Move pointer to start position of match
  unless ($forward->skip_pos($match->start)) {

    # This should never happen!
    return;
  };

  # Get data from hit
  my $hit_data = $self->{hit}->content($match, $forward);

  if (DEBUG) {
    print_log('c_snippet', 'Move to match position');
  };

  # Create snippet posting
  my $snippet = Krawfish::Koral::Result::Enrich::Snippet->new(
    hit_ids => $hit_data
  );

  # Add snippet to match
  $match->add($snippet);

  # Deal with left
  # Deal with hit
  # Deal with right

  $self->{match} = $match;
  return $match;
};


# Stringification
sub to_string {
  my $self = shift;
  my $str = 'snippet(';
  if ($self->{left}) {
    $str .= $self->{left}->to_string . ',';
  };
  if ($self->{right}) {
    $str .= $self->{right}->to_string . ',';
  };
  $str .= $self->{hit}->to_string . ':';
  $str .= $self->{query}->to_string;
  return $str . ')';
};


1;
