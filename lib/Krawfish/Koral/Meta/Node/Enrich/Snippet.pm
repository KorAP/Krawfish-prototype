package Krawfish::Koral::Meta::Node::Enrich::Snippet;
use Krawfish::Result::Segment::Enrich::Snippet;
use Krawfish::Util::String qw/squote/;
use Krawfish::Query::Nowhere;
use strict;
use warnings;

# TODO:
#   Inflate on the enrichments!
#
# TODO:
#   Support contexts etc.

sub new {
  my $class = shift;
  bless {
    query => shift,
    options => shift
  }, $class;
};


sub options {
  $_[0]->{options};
};

sub to_string {
  my $self = shift;
  return 'snippet(?:' . $self->{query}->to_string . ')';
};


# TODO:
#   This needs to convert annotations etc.
sub identify {
  my ($self, $dict) = @_;
  $self->{query} = $self->{query}->identify($dict);
  return $self;
};


sub optimize {
  my ($self, $segment) = @_;

  my $query = $self->{query}->optimize($segment);

  if ($query->max_freq == 0) {
    return Krawfish::Query::Nowhere->new;
  };

  return Krawfish::Result::Segment::Enrich::Snippet->new(
    $query,
    $segment->forward,
    $self->options,
  );
};

1;
