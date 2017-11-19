package Krawfish::Koral::Result::Enrich::Snippet;
use strict;
use warnings;
use Role::Tiny::With;

with 'Krawfish::Koral::Result::Inflatable';

# The structure of a match is as follows:
#
# <context>
#   <more />
#   ...             # Pure text and decorations
#   <focus>         # Possible extension to elements
#     ...           # Pure text, decorations and annotations
#     <hit>         # The concrete hit
#       ...         # Pure text, decorations, annotations and highlights
#     </hit>
#     ...           # Pure text, decorations and annotations
#   </focus>
#   ...             # Pure text and decorations
#   <more />
# </context>


# TODO:
#   Make sure this works for right-to-left (RTL) language scripts as well!


# Constructor
sub new {
  my $class = shift;

  # stream
  # stream_offset
  # doc_id

  # match_ids
  my $self = bless {
    @_
  }, $class;


  $self->{annotations} //= [];
  return $self;
};


# Inflate term ids to terms
sub inflate {
  my ($self, $dict) = @_;

  # Inflate the stream
  $self->stream($self->stream->inflate($dict));

  #my $hit = $self->{hit_ids};
  #for (my $i = 0; $i < @$hit; $i++) {
  #  $hit->[$i] = $hit->[$i]->inflate($dict);
  #};
  return $self;
};


# Set doc id
sub doc_id {
  my $self = shift;
  if (@_) {
    $self->{doc_id} = shift;
    return $self;
  };
  return $self->{doc_id};
};


# This stores a Krawfish::Koral::Document::Stream
# with the stream_offset subtoken at 0
sub stream {
  my $self = shift;
  if (@_) {
    $self->{stream} = shift;
    return $self;
  };
  return $self->{stream};
};


# Get the offset for stream positions
sub stream_offset {
  my $self = shift;
  if (@_) {
    $self->{stream_offset} = shift;
    return $self;
  };
  return $self->{stream_offset};
};


# Stringification
sub to_string {
  my ($self, $id) = @_;
  my $str = $self->key . ':' . $self->stream->to_string($id);
};


# Key for KQ serialization
sub key {
  'snippet'
};


# Serialize KQ
sub to_koral_fragment {
  my $self = shift;

  return $self->stream->to_string
};


sub _order_markup {
  my ($self, $stream) = @_;
  # This is based on processHighlightStack() in Krill
  #
  # 1. Take all markup and split into opening and closing tags
  #    - Milestones are only added as starts
  my (@open, @close);
  # 2. Sort the open tags:
  #    - by start position
  #    - by start character extension
  #    - by end position
  #    - by class number / depth
  #    - by annotation term
  #    - by certainty
  # 3. Sort the closing tags
  #    - by end position
  #    - by end character extension
  #    - by start position
  #    - by class number /depth
  #    - by annotation term
  #    - by certainty
  # 4. Create a stack or a list of the doubled length of
  #    the opening list
  my @stack;

  while (@open || @close) {

    # No more open tags
    if (!@open) {
      push @stack, pop @close;
      next;
    }

    # No more end tags
    elsif (!@close) {
      last;
    };

    # The opener starts before the closer ends
    if ($open[0] < $close[0]) {
      push @stack, shift @open;
    }

    # First let the closer end
    else {
      push(@stack, shift(@close));
    };
  };

  return @stack;

  # 5. Iterate over the stream and add all annotations.
  #    Stream is:
  #    Krawfish::Koral::Document::Stream
  #    with surface annotations only
  my $length = $self->stream->length;
  while ($length > 0) {
    ...
  };
};

# Add annotation
sub add {
  my $self = shift;
  my $e = shift;

  # Add markup objects
  if (Role::Tiny::does_role($e, 'Krawfish::Koral::Result::Enrich::Snippet::Markup')) {
    # Add the hit boundaries
    if ($e->isa('Krawfish::Koral::Result::Enrich::Snippet::Hit')) {
      $self->hit_start($e->start);
      $self->hit_end($e->end);
    }

    # Context information
    elsif ($e->isa('Krawfish::Koral::Result::Enrich::Snippet::Context')) {
      $self->context_start($e->start);
      $self->context_end($e->end);
    }

    # Scope extended by, e.g., spans
    elsif ($e->isa('Krawfish::Koral::Result::Enrich::Snippet::Focus')) {
      $self->focus_start($e->start);
      $self->focus_end($e->end);
    };

    # Push to annotation list
    push @{$self->{annotations}}, $_[0];
  };
};



# Set context start position
sub context_start {
  my $self = shift;
  if (@_) {
    $self->{context_start} = shift;
    return $self;
  };
  return $self->{context_start};
};


# Set context end position
sub context_end {
  my $self = shift;
  if (@_) {
    $self->{context_end} = shift;
    return $self;
  };
  return $self->{context_end};
};



# Set extension start position
sub focus_start {
  my $self = shift;
  if (@_) {
    $self->{focus_start} = shift;
    return $self;
  };
  return $self->{focus_start};
};


# Set extension end position
sub focus_end {
  my $self = shift;
  if (@_) {
    $self->{focus_end} = shift;
    return $self;
  };
  return $self->{focus_end};
};


# Set hit start position
sub hit_start {
  my $self = shift;
  if (@_) {
    $self->{hit_start} = shift;
    return $self;
  };
  return $self->{hit_start};
};


# Set hit end position
sub hit_end {
  my $self = shift;
  if (@_) {
    $self->{hit_end} = shift;
    return $self;
  };
  return $self->{hit_end};
};




1;
