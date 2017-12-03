package Krawfish::Compile::Node;
use strict;
use warnings;
use Role::Tiny;

# Create a class for result aggregation on the node level.

warn 'Currently unused!';


# TODO:
#   Add a timeout! Just in case ...!

sub new {
  my $class = shift;
  my $self = bless {
    aggregation => [], # Array of aggregation methods

    # The sorting criteria for the buffer
    sorting => [],

    query => undef,
    indexes => [],
    data => undef,
    groups => {},  # Store all groups
  }, $class;


  # Building a merge sorting buffer
  $self->{buffer} = Krawfish::Compile::Node::SortingBuffer->new(
    scalar @{$self->{indexes}}, # Size of the buffer
    $self->{sorting}            # Criteria for sorting
  );
  return $self;
};


# Get or set rank reference value
# This is useful for sorting coordination between processes
sub max_rank_reference {
  my $self = shift;

  if (@_) {
    $self->{max_rank_ref} = shift;
    return $self;
  };

  return $self->{max_rank_ref};
};


# Overwrite process_head and pass to deeper query
sub process_head {
  my ($self, $head) = @_;
  $_[0]->{query}->process_head($head);
  return;
};


sub buffer {
  return $_[0]->{buffer};
};


# Open all channels and send the query
# Initially this will return all aggregate data and,
# in case it is a group query, all groups.
sub open {
  my $self = shift;
  foreach my $index (@{$self->{indexes}}) {

    CORE::next if $index->is_closed;

    # Send query to all channels in parallel
    # Note if one index is not available
    $index->send(
      $self->{query} => sub {

        # Get the initial aggregation data -
        # aggregate in new data hash
        my ($aggregates, $groups) = @_;
        $self->aggregation($aggregates);
        $self->grouping($groups);
      });
  };

  return 1;
};


# Go to next position
sub next {
  my $self = shift;

  # Get next element from buffer
  $self->{current} = $self->buffer->shift;

  unless ($self->{current}) {
    $self->{current} = $self->_next_current or return;
  };

  return 1;
};


# Fill the buffer with the next matches,
# sorted by the criterion.
# close indexes no longer needed.
sub _next_current {
  my $self = shift;


  # TODO:
  #    this does not work for indexes with sorted items like:
  #
  #    1. 1 8 9
  #    2. 2 4 5  <- here, the 4 is before 5!
  #    3. 5 6 8
  #
  foreach my $index (@{$self->{indexes}}) {

    CORE::next if $index->is_closed;

    # remember index to get current_match
    # TODO:
    #   Probably use next_current
    my $current = $index->next_current;

    # No more matches from this index
    unless ($current) {

      # Close the index
      $index->close;
      CORE::next;
    };

    $self->buffer->push($index, $current);

  };

  return $self->buffer->pop;
};


# Close all indexes still open
sub close_all {
  my $self = shift;

  # Iterate over all indexes
  foreach my $index (@{$self->{indexes}}) {

    # Index already closed
    CORE::next if $index->is_closed;

    # Close index
    $index->close();
  };

  # Remove all indexes
  $self->{indexes} = [];
};


# Get current
sub current {
  my $self = shift;

  # Get current field if available
  my $current = $self->{current}->[1] or return;

  # TODO:
  #   Rewrite criterion to criterion strings!
};


# Get current match (including criterion string
sub current_match {
  my $self = shift;

  # Get current field if available
  my $current_index = $self->{current}->[0] or return;

  # This should never haben, because it calls a closed index
  return if $current_index->is_closed;

  # Return the match
  return $current_index->current_match;
};


# Aggregate all data using the aggregation mechanisms
sub aggregate {
  my ($self, $data) = @_;

  foreach my $aggr (@{$self->{aggregation}}) {
    $aggr->aggregate($data);
  };

  return 1;
};

1;
