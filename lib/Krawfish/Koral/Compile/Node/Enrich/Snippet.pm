package Krawfish::Koral::Compile::Node::Enrich::Snippet;
use Krawfish::Compile::Segment::Enrich::Snippet;
use Krawfish::Util::String qw/squote/;
use Krawfish::Compile::Segment::Nowhere;
use strict;
use warnings;

# TODO:
#   Inflate on the enrichments!
#
# TODO:
#   Support contexts etc.

sub new {
  my $class = shift;
  bless { @_ }, $class;
};


sub to_string {
  my ($self, $id) = @_;
  my $str = 'snippet(hit';
  if ($self->{left}) {
    $str .= ',left=' . $self->{left}->to_string($id);
  };
  if ($self->{right}) {
    $str .= ',right=' . $self->{right}->to_string($id);
  };

  if ($self->{highlights}) {
    $str .= ',hls=[' . join(',', @{$self->{highlights}}) . ']';
  };

  if ($self->{format}) {
    $str .= ',format=' . $self->{format};
  };

  #  $str .= $self->{hit}->to_string;
  $str .= ':' . $self->{query}->to_string($id) . ')';
};


# TODO:
#   This needs to convert annotations etc.
sub identify {
  my ($self, $dict) = @_;

  # Identify contexts
  # This may result in undef (no context) in case
  # the requested span or token foundry does not exist
  if ($self->{left}) {
    $self->{left} = $self->{left}->identify($dict);
  };
  if ($self->{right}) {
    $self->{right} = $self->{right}->identify($dict);
  };

  # Identify hit
  # This will at least define a "surface only" hit object,
  # even if requested annotations do not exist
  # $self->{hit} = $self->{hit}->identify($dict);

  # Identify query
  $self->{query} = $self->{query}->identify($dict);

  return $self;
};


# Optimize query for segment
sub optimize {
  my ($self, $segment) = @_;

  # Optimize query
  my $query = $self->{query}->optimize($segment);

  # Nothing to return
  if ($query->max_freq == 0) {
    return Krawfish::Compile::Segment::Nowhere->new;
  };

  # Create left context object
  my $left = $self->{left};
  if ($left) {
    $left = $left->optimize($segment);
  };

  # Create left context object
  my $right = $self->{right};
  if ($right) {
    $right = $right->optimize($segment);
  };

  # Optimize hit
  # $self->{hit} = $self->{hit}->optimize($segment);

  # Return snippet object
  return Krawfish::Compile::Segment::Enrich::Snippet->new(
    query   => $query,
    fwd_obj => $segment->forward,
    # hit     => $self->{hit},
    highlights => $self->{highlights},
    format  => $self->{format},
    left    => $left,
    right   => $right
  );
};

1;
