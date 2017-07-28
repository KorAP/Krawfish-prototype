package Krawfish::Controller::Index;
use Mojo::Base 'Mojolicious::Controller';
use Krawfish::Cluster;
use Krawfish::Koral;
use strict;
use warnings;

sub add {
  my $c = shift;
  my $kq = $c->koral->error(000, 'Index creation not yet implemented');
  $c->render(json => $kq);
};


# The search API first searches for matches, then retrieves information
# per match identical to the match API
sub search {
  my $c = shift;
  my $json = $c->req->body->json;

  # TODO:
  #   This is just conceptually for the moment

  # Read koral from json input
  $koral = Krawfish::Koral->new;

  # There is something seriously wrong
  unless ($koral->from_koral_query($json)) {
    # Query can't be serialized!
    return $c->reply->exception('Unable to parse KoralQuery');
  };

  # Create a response object
  my $response = $koral->clone;
  # TODO:
  #   Or clone on normalization???

  # Prepare passed query to nodes
  my $node_koral = $koral->to_nodes;

  # Something went wrong during normalization
  unless ($node_koral) {
    $response->copy_info_from($koral);
    return $c->render(json => $response);
  };

  # Nothing matches
  if ($node_koral->is_nothing) {
    $response->copy_info_from($koral);
    warn 'Matches nowhere - no reason to send to nodes';
    return $c->render(json => $response->to_koral_query);
  };

  # Get nodes object
  my $cluster = Krawfish::Cluster->new;

  # Send to all nodes
  $node_koral->send(
    $cluster => (

      # This sub will be triggered for each node
      sub {
        my ($query, $node) = @_;

        # Process the head data
        $query->process_head($node->response->head);
      },

      # This sub will triggered after all nodes were passed
      sub {
        my $query = shift;

        # Add result to response
        $response->{response} = $query->to_response;

        # Return koral query response
        return $c->render(json => $response->to_koral_query);
      }
    )
  );
};


1;
