package Krawfish::Koral::Result::Enrich::Snippet;
use strict;
use warnings;
use Role::Tiny::With;

with 'Krawfish::Koral::Result::Inflatable';


# TODO:
#   Make sure this works for right-to-left (RTL) language scripts as well!


# Constructor
sub new {
  my $class = shift;

  # match_ids
  bless {
    @_
  }, $class;
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


# Set context end position
sub context_end {
  my $self = shift;
  if (@_) {
    $self->{context_end} = shift;
    return $self;
  };
  return $self->{context_end};
};


# Set extension end position
sub extension_end {
  my $self = shift;
  if (@_) {
    $self->{extension_end} = shift;
    return $self;
  };
  return $self->{extension_end};
};


# Set context start position
sub hit_start {
  my $self = shift;
  if (@_) {
    $self->{hit_start} = shift;
    return $self;
  };
  return $self->{hit_start};
};


# Set context end position
sub hit_end {
  my $self = shift;
  if (@_) {
    $self->{hit_end} = shift;
    return $self;
  };
  return $self->{hit_end};
};


# Add highlight to snippet
sub add_highlight {
  my ($self, $highlight) = @_;
  my $hls = ($self->{highlights} //= []);
  push @$hls, $highlight;
};


# Add annotations to be retrieved in hit
sub add_annotation {
  ...
};


# All annotations to be retrieved in hit
sub annotations_sorted {
  # TODO:
  #   Sort all requested annotations numerically by
  #   foundry_id > layer_id > anno_id!
  return ();
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


1;
