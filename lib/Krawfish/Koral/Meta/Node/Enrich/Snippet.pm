package Krawfish::Koral::Meta::Node::Enrich::Snippet;
use Krawfish::Result::Segment::Enrich::Snippet;
use Krawfish::Util::String qw/squote/;
use Krawfish::Query::Nothing;
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
  my $self = shift;
  my $str = 'snippet(';
  if ($self->{left}) {
    $str .= 'left=' . $self->{left}->to_string . ',';
  };
  if ($self->{right}) {
    $str .= 'right=' . $self->{right}->to_string . ',';
  };
  $str .= $self->{match}->to_string;
  $str .= ':' . $self->{query}->to_string . ')';
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

  # Identify match
  # This will at least define a "surface only" match object,
  # even if requested annotations do not exist
  $self->{match} = $self->{match}->identify($dict);

  # Identify query
  $self->{query} = $self->{query}->identify($dict);

  return $self;
};


sub optimize {
  my ($self, $segment) = @_;

  my $query = $self->{query}->optimize($segment);

  if ($query->max_freq == 0) {
    return Krawfish::Query::Nothing->new;
  };

  return Krawfish::Result::Segment::Enrich::Snippet->new(
    $query,
    $segment->forward,
    {},
  );
};

1;
