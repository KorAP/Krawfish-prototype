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

  # TODO:
  #   1. Choose the two best nodes, make one primary and the second
  #      replicant.
  #   2. $cluster->import($primary, $secondary);
  #      if one of them fails, choose another one.
  #   3. Return a unique commit-ID
};


# Receive information regarding a specific commit
sub commit_info {
  my $c = shift;
  my $commit_id = $c->stash('commit_id');

  # List all commits
  unless ($commit_id) {
    ...
  };
  ...
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

  # Send query to all nodes
  $cluster->search_for(
    $node_koral => sub {
      my $response = shift;

      # Add result to response
      $response->{response} = $query->to_response;

      # Return koral query response
      return $c->render(json => $response->to_koral_query);
    }
  );
};


1;
