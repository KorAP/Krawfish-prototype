package Krawfish::Koral::Compile::Node::Merge;

# TODO:
#   THIS IS WRONG HERE!

use Krawfish::Compile::Node;

# TODO:
#   May require Node::nowhere!
use Krawfish::Compile::Segment::Nowhere;
use Krawfish::Log;
use strict;
use warnings;

# TODO:
#   This runs on the node level
#   and is different to all other
#   Krawfish::Koral::Compile::Node::* queries

use constant DEBUG => 0;


sub new {
  my $class = shift;

  bless {
    query  => shift,
    top_k  => shift // 100,
  }, $class;
};


# Query type
sub type {
  'node_merge';
};


# Identify query
sub identify {
  my ($self, $dict) = @_;
  $self->{query} = $self->{query}->identify($dict);
  return $self;
};


# Optimize query to segments
sub optimize {
  my ($self, $segments) = @_;

  # Accept a single segment as well
  $segments = ref $segments ne 'ARRAY' ? [$segments] : $segments;

  if (DEBUG) {
    print_log(
      'kq_n_merge',
      'Optimize query on node level'
      );
  };


  # Optimize queries for segments
  my @queries;
  foreach my $seg (@$segments) {
    my $segment_query = $self->{query}->optimize($seg);

    if (DEBUG) {
      print_log('cmp_node', 'Add query ' . $segment_query->to_string . ' to merge');
    };

    # There are results expected
    if ($segment_query->max_freq != 0) {
      push @queries, $segment_query;
    };
  };

  # Query does not require sorted result
  if (Role::Tiny::does_role($self->{query}, 'Krawfish::Koral::Compile::Node::Group')) {
    $self->{top_k} = 0;
  };

  # Create new node query
  my $query = Krawfish::Compile::Node->new(
    top_k => $self->{top_k},
    queries => \@queries
  );

  if ($query->max_freq == 0) {
    return Krawfish::Compile::Segment::Nowhere->new;
  };

  return $query;
};



# Stringification
sub to_string {
  my ($self, $id) = @_;

  my $str = 'node(';

  if ($self->{top_k}) {
    $str .= 'k=' . $self->{top_k} . ':';
  };

  return $str . $self->{query}->to_string($id) . ')';
};


1;
