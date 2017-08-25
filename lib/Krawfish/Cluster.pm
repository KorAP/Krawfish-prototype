package Krawfish::Cluster;
use Mojo::IOLoop;
use strict;
use warnings;

# Krawfish::Cluster queries to multiple nodes
# and takes care of failures in responses

# See http://verdi.uwplse.org/


sub new {
  my $class = shift;
  bless {
    nodes => []
  }, $class;
};


# Search for a query and return a response
sub search_for {
  my ($self, $query, $cb) = @_;

  # This should probably open multiple websockets/unix-sockets in parallel
  # https://stackoverflow.com/questions/13417000/synchronous-request-with-websockets
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      foreach my $node (@{$self->{nodes}}) {
        $ua->post($node => json => $query => $delay->begin);
      };
    },
    sub {
      my $delay = shift;

      # Iterate over all results
      foreach (@_) {

        if ($_->error) {
          next;
          # retry! to_nodes($_->node_id);
        };

        # Responses have a head and a tail section
        # In case, no aggregation or grouping is done,
        # there is no head section.
        # In case, there is grouping, there is no
        # tail.
        my $response = $_->res->json;

        # TODO:
        #   If a node has no positive status,
        #   reformulate the query for the redundant value of the node
        #   and resend to all other nodes.


        # Aggregate data, e.g. for grouping
        $query->process_head($response->{head});

        # Get through the matches
        # TODO:
        #   This is, however, bad for merge sort!
        $query->process_tail($response->{tail});
      };
    }
  )->wait;

  return $query->to_result;
};


# Initialize a sortable field
sub init_field {
  my ($self, $field_term, $type, $collation) = @_;
  # Non-initialized fields are stored and searchable,
  # but they can't be sorted
  ...
};


1;
