package Krawfish::Koral::Compile::Node;
use Krawfish::Koral::Compile::Node::Merge;
use Krawfish::Log;
use strict;
use warnings;

# Koral class to join query results on node level

use constant DEBUG => 0;

sub new {
  my $class = shift;

  if (DEBUG) {
    print_log('kq_node', 'Add node level merging');
  };

  # Pass top_k information
  bless {
    top_k => shift
  }, $class;
};


# Query type
sub type {
  'node_merge';
};


# Normalize query
sub normalize {
  $_[0];
};


# Wrap query object
sub wrap {
  my ($self, $query) = @_;

  if (DEBUG) {
    print_log('kq_node', 'Wrap query in a node_merge query: ' . $query->to_string);
  };

  return Krawfish::Koral::Compile::Node::Merge->new(
    $query,
    $self->{top_k}
  );
};


# Stringification
sub to_string {
  my $self = shift;
  return 'node=[k=' . ($self->{top_k} // '-') . ']';
};


1;


__END__
