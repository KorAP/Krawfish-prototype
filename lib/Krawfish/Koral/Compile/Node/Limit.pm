package Krawfish::Koral::Compile::Node::Limit;

# TODO:
#   Limiting can only be done on the cluster level!

use Krawfish::Compile::Cluster::Limit;
use Krawfish::Compile::Segment::Nowhere;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

sub new {
  my $class = shift;

  my $self = bless {
    query => shift,
    start_index => shift,
    items_per_page => shift
  }, $class;
};


# Get identifiers
sub identify {
  my ($self, $dict) = @_;

  $self->{query} = $self->{query}->identify($dict);

  return if $self->{items_per_page} == 0;

  return $self;
};


sub to_string {
  my $self = shift;
  return 'limit(' . $self->{start_index} . '-' .
    ($self->{start_index} + $self->{items_per_page}) .
    ':' .
    $self->{query}->to_string .
    ')';
};


sub optimize {
  my ($self, $segment) = @_;

  my $query = $self->{query}->optimize($segment);

  if ($query->max_freq == 0) {
    return Krawfish::Compile::Segment::Nowhere->new;
  };

  return Krawfish::Compile::Limit->new(
    $query,
    $self->{start_index},
    $self->{items_per_page}
  )
};

1;
