package Krawfish::Compile::Segment::Enrich::Snippet;
use strict;
use warnings;
use parent 'Krawfish::Compile';
use Krawfish::Koral::Result::Enrich::Snippet;
# use Krawfish::Compile::Segment::Enrich::Snippet::Highlights;
use Krawfish::Koral::Document::Stream;
use Krawfish::Koral::Document::Subtoken;
use Krawfish::Log;

use constant DEBUG => 1;

# TODO:
#   It may be more efficient to first collect all required
#   annotations (for decoration, context, hit etc.) and
#   then iterate over left context, hit, right context
#   and get all annotations per token at a time

#   1. Check the starting position of the context

#   2. So, create an abstract Snippet object.
#      - Set hit subtoken positions
#      - Set context (as far as known)
#      - Set highlights
#      - Set relevant char extensions

#   3. Pass the forward index to the snippet object
#      - Fetch all relevant annotations
#      - Add match boundary (respect char extensions)
#      - Add highlights (respect char extensions)
#      - Add inline information (e.g. for pagebreak numbers)
#      - Extend to context boundary
#      - Serialize snippet


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


# Get extension element
sub extension {
  $_[0]->{extension}
};


# Get left context object
sub left_context {
  $_[0]->{left};
};


# Get right object context
sub right_context {
  $_[0]->{right};
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

  print_log('c_snippet', 'match is ' . $match->to_string) if DEBUG;

  # Get forward query
  my $forward = $self->{fwd_pointer};

  my $doc_id = $match->doc_id;

  # Move to current document
  # THIS SHOULD NEVER FAIL!
  return unless $forward->skip_doc($doc_id) == $doc_id;

  # Move pointer to start position of match
  unless ($forward->skip_pos($match->start)) {

    # In case the last match was overlapping with the current match, the forward
    # pointer needs to move backward step by step
    while ($forward->pos > $match->start) {
      $forward->prev;
    };
  };

  # Create new snippet object
  my $new_snippet = Krawfish::Koral::Result::Enrich::Snippet->new(
    hit_start => $match->start,
    hit_end => $match->end
  );


  # TODO:
  #   Check for classes with supported highlights!
  foreach my $highlight ($match->get_classes) {

    # Add highlight
    $new_snippet->add_highlight($highlight);
  };


  # TODO:
  #   Add character extensions from match's payload

  # Initialize context
  my (
    $left_start,              # The first subtoken in the context
    $left_start_ext_char,     # A potential character extension to the left
    $right_min_end,           # The minimum last subtoken in the context
    $right_min_end_ext_char   # A potential character extension to the right
  ) = ($match->start, 0, $match->end, 0);


  # TODO:
  #   Extend to an arbitrary element surrounding
  if ($self->extension) {

    # $self->extension->start ...
    # $new_snippet->hit_start();
    # $new_snippet->extension_end();
  }

  else {

    # set optional extension end to same value as hit end
    $new_snippet->extension_end($new_snippet->hit_end);
  };

  # Get context, if left context is defined
  if ($self->left_context) {
    ($left_start, $left_start_ext_char, $right_min_end, $right_min_end_ext_char) =
      $self->left_context->start($forward);

    # The pointer now is set to the context's start
    # Set context end
    $new_snippet->context_end($right_min_end);
  };


  # Fetch information from forward index
  $self->_fetch_stream($new_snippet);

  # Add snippet to match
  $match->add($new_snippet);

  $self->{match} = $match;
  return $match;


  # This is the old Snippet retrieval:

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



# Add all relevant annotations from the forward stream
# TODO:
#   This needs to respect character extensions!
sub _fetch_stream {
  my ($self, $snippet) = @_;

  # Get forward query
  my $forward = $self->{fwd_pointer};

  my $i = 0;

  # Stream of forward postings
  my $stream = Krawfish::Koral::Document::Stream->new;

  # Set offset
  $snippet->stream_offset($forward->pos);

  # Retrieve the primary data only
  while ($forward->pos < $snippet->hit_start) {

    # Get current posting
    my $current = $forward->current;

    # Add Subtoken to stream
    $stream->subtoken(
      $i++,
      Krawfish::Koral::Document::Subtoken->new(
        # (Needs to be renamed to preceding_enc)
        preceding_enc => $current->preceding_data,
        subterm_id => $current->term_id
      )
    );
    last unless $forward->next;
  };


  # Retrieve the hit data including annotations!
  while ($forward->pos < $snippet->hit_end) {

    # Get current posting
    my $current = $forward->current;

    # Add Subtoken to stream
    my $subtoken = $stream->subtoken(
      $i++,
      Krawfish::Koral::Document::Subtoken->new(
        # (Needs to be renamed to preceding_enc)
        preceding_enc => $current->preceding_data,
        subterm_id => $current->term_id
      ));

    last unless $forward->next;
    # TODO:
    #   $subtoken->add_annotation(
    #    Krawfish::Koral::Document::Annotation->()
    #   );
  };

  #if ($self->extension) {
  #};

  #if ($self->right_extension) {
  #};

  # TODO:
  #   Add one more subtoken for preceding data, so in case
  #   of right extensions, the character data is correctly retrieved!

  $snippet->stream($stream);
  return;
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
