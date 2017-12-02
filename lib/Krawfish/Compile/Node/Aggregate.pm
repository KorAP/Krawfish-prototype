package Krawfish::Compile::Node::Aggregate;
use strict;
use warnings;
use Role::Tiny;

# with 'Krawfish::Compile::Node';

# TODO:
#   Implement the aggregate() method on all Node::Aggregate::*

# May be renamed to
# - Krawfish::MultiSegment::Aggregate
# - Krawfish::MultiNodes::Aggregate

# To aggregate top_k matches from multiple segments,
# fetch all top segments and put them in a
# priority queue. Get top match, and request the next
# match from that segment.
# Do this, until k is fine.

# Distributed results are returned from each index
# in an aggregate data section followed by result lines.
# The result lines can be returned using next_current() etc.
# while the data aggregation section is returned by the first
# call.



1;


__END__

sub new {
  my $class = shift;
  bless {
    query => shift,
    aggregates => shift,
    _fetched => undef,
    _result => undef
  }, $class;
};


# This will read all header information from the nodes
# and aggregate the date
sub process_head {
  my ($self, $head) = @_;

  # Get aggregation data from head
  my $data = $head->{aggregate};

  # Iterate over all registered aggregates
  foreach (@{$self->{aggregates}}) {

    # Aggregate head data
    $_->aggregate($data);
  };

  # Go deeper
  $self->{query}->process_head($head);
};



# Get result information
# Maybe "on final"
sub result {
  my $self = shift;

  # Fetch all aggregation data from the types
  my $result = {};

  # Add to result hash
  foreach my $op (@{$self->{aggregates}}) {
    $result->{$op->type} = $op->aggregate;
  };
};


# Next query line - do nothing
sub next {
  $_[0]->{query}->next;
};



sub to_string {
  my $self = shift;
  return 'aggr(' .
    join(',', map { $_->to_string } @{$self->{aggregates}}) .
    ':' . $self->{query}->to_string . ')';
};


1;
