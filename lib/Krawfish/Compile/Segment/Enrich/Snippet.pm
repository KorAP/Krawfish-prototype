package Krawfish::Compile::Segment::Enrich::Snippet;
use strict;
use warnings;
use Krawfish::Koral::Result::Enrich::Snippet;
# use Krawfish::Compile::Segment::Enrich::Snippet::Highlights;

use Krawfish::Koral::Result::Enrich::Snippet::Hit;
use Krawfish::Koral::Result::Enrich::Snippet::Highlight;

use Krawfish::Koral::Document::Stream;
use Krawfish::Koral::Document::Subtoken;
use Krawfish::Log;
use Role::Tiny;

with 'Krawfish::Compile::Segment';

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

#   3. Fetch all relevant annotations
#      - Add match boundary (respect char extensions)
#      - Add decorators
#      - Add highlights (respect char extensions)
#      - Add inline information (e.g. for pagebreak numbers)
#      - Extend to context boundary
#      - Serialize snippet

# TODO:
#   It may be useful to include some flagOptional-Queries,
#   that will add attributes to matches (Payloads?),
#   that can be checked before enriching with snippets.
#   In that way, it can be checked, if a match has an
#   'right-to-left' meta-field so the snippet is displayed in reverse
#   order. Or it is checked, if a specific license is used, so the decorators
#   need to apply for every token.
#   E.g. check using an ifCorpus() query, if a match has a certain flag set.
#   But how would this be serialized in a query?

sub new {
  my $class = shift;
  # - query
  # - fwd_obj
  # - left
  # - right
  # - hit
  #
  # TODO:
  #   Pass highlight class list
  return bless { @_ }, $class;
};


# Clone snippet object
sub clone {
  my $self = shift;
  __PACKAGE__->new(
    query     => $self->{query}->clone,
    fwd_obj   => $self->{fwd_obj},
    left      => $self->{left},
    right     => $self->{right},
    extension => $self->{extension},
    hit       => $self->{hit}
  );
};


# Initialize forward index
sub _init {
  return if $_[0]->{_init}++;

  my $self = shift;
  $self->{fwd_pointer} = $self->{fwd_obj}->pointer;
};


# Iterate through the ordered matches
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

  if (DEBUG) {
    print_log('c_snippet', 'match is ' . $match->to_string(1));
  };

  # Create hit object
  my $hit = Krawfish::Koral::Result::Enrich::Snippet::Hit->new(
    start => $match->start // 0,
    end   => $match->end // 0
  );

  # TODO:
  #   Adjust expansion to hit / or only use context for that!

  # TODO:
  #   Match may have different start_char, end_char values!

  # Create new snippet result object
  my $new_snippet = Krawfish::Koral::Result::Enrich::Snippet->new(
    doc_id    => $match->doc_id
  );

  # Add hit object
  $new_snippet->add($hit);

  # TODO:
  #   Add context enrichments to snippet

  # Retrieve classes from match
  foreach my $highlight ($match->get_classes) {

    # Ignore hit-class
    next if $highlight->[0] == 0;

    # TODO:
    #   Check for classes with supported highlights!


    if ($highlight->[0] >= $new_snippet->hit_start &&
          $highlight->[1] <= $new_snippet->hit_end) {

      my $e = Krawfish::Koral::Result::Enrich::Snippet::Highlight->new(
        number => $highlight->[0],
        start  => $highlight->[1],
        end    => $highlight->[2]
      );

      # TODO:
      #   Probably respect character extensions from match's payload

      # Add highlight
      $new_snippet->add($e);
    };
  };

  # Fetch information from forward index
  $self->_fetch_stream($new_snippet) or return;

  # Add snippet to match
  $match->add($new_snippet);

  $self->{match} = $match;
  return $match;
};


# Get possible extension element, that will extend the scope
# of the hit to the match
sub extension {
  $_[0]->{extension}
};


# Get left context object
sub left_context {
  $_[0]->{left};
};


# Get right context object
sub right_context {
  $_[0]->{right};
};



# Add all relevant annotations from the forward stream
# from the start to the end - including extensions and context!
# TODO:
#   This needs to respect character extensions!
sub _fetch_stream {
  my ($self, $snippet) = @_;

  # Get pointer to forward stream
  my $forward = $self->{fwd_pointer};

  my $doc_id = $snippet->doc_id;

  # Move to current document
  # THIS SHOULD NEVER FAIL!
  return unless $forward->skip_doc($doc_id) == $doc_id;

  # Move pointer to start position of match
  unless ($forward->skip_pos($snippet->hit_start)) {

    # In case the last match was overlapping with the current match,
    # the forward pointer needs to move backward step by step
    while ($forward->pos > $snippet->hit_start) {
      $forward->prev;
    };
  };

  # THIS SHOULD NEVER FAIL!
  if ($forward->pos != $snippet->hit_start) {
    return;
  };

  if (DEBUG) {
    print_log(
      'c_snippet',
      'Retrieve annotation data for match starting at ' . $snippet->hit_start
    );
  };

  # Initialize context
  my (
    $left_start,              # The first subtoken in the context
    $left_start_ext_char,     # A potential character extension to the left
    $right_min_end,           # The minimum last subtoken in the context
    $right_min_end_ext_char   # A potential character extension to the right
  ) = ($snippet->hit_start, 0, $snippet->hit_end, 0);


  # TODO:
  #   Extend to an arbitrary element surrounding
  if ($self->extension) {

    # $self->extension->start ...
    # $new_snippet->hit_start();
    # $new_snippet->extension_end();
  }

  else {

    # set optional extension end to same value as hit end
    $snippet->focus_end($snippet->hit_end);
  };

  # Get context, if left context is defined
  if ($self->left_context) {
    ($left_start, $left_start_ext_char, $right_min_end, $right_min_end_ext_char) =
      $self->left_context->start($forward);

    # The pointer now is set to the context's start
    # Set context end
    $snippet->context_end($right_min_end);
  };


  my $i = 0;

  # Stream of forward postings
  my $stream = Krawfish::Koral::Document::Stream->new;

  # Set offsets
  $snippet->stream_offset($forward->pos);
  $snippet->stream_offset_char($left_start_ext_char);

  # TODO:
  #   Respect extension!

  # Retrieve the primary data only
  while ($forward->pos < $snippet->hit_start) {

    # Get current posting
    my $current = $forward->current;

    my $subtoken = Krawfish::Koral::Document::Subtoken->new(
      # (Needs to be renamed to preceding_enc)
      preceding_enc => $current->preceding_data,
      subterm_id => $current->term_id
    );

    # Add Subtoken to stream
    $stream->subtoken($i++, $subtoken);

    # TODO:
    #   Check and remember decorators if requested

    last unless $forward->next;
  };

  # Retrieve the hit data including annotations!
  while ($forward->pos < $snippet->hit_end) {

    # Get current posting
    my $current = $forward->current;

    my $subtoken = Krawfish::Koral::Document::Subtoken->new(
      # (Needs to be renamed to preceding_enc)
      preceding_enc => $current->preceding_data,
      subterm_id => $current->term_id
    );

    # Add Subtoken to stream
    $stream->subtoken($i++, $subtoken);

    last unless $forward->next;
    # TODO:
    #   $snippet->add(
    #      Krawfish::Koral::Document::Annotation->()
    #      or
    #      Krawfish::Koral::Result::Enrich::Snippet::Span etc.
    #   );

    # TODO:
    #   Check and remember decorators if requested
  };

  #if ($self->extension) {
  #};

  #if ($self->right_extension) {
  #};

  # TODO:
  #   Add one more subtoken for preceding data, so in case
  #   of right extensions, the character data is correctly retrieved!

  $snippet->stream($stream);
  return 1;
};




# Stringification
sub to_string {
  my ($self, $id) = @_;
  my $str = 'eSnippet(hit';
  if ($self->{left}) {
    $str .= ',' . $self->{left}->to_string($id);
  };
  if ($self->{right}) {
    $str .= ',' . $self->{right}->to_string($id);
  };
  $str .= ':' . $self->{query}->to_string($id);
  return $str . ')';
};


1;
