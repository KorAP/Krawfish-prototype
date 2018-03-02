package Krawfish::Compile::Node;
use Array::Queue::Priority;
use Krawfish::Util::Heap;
use Krawfish::Log;
use Role::Tiny::With;
use strict;
use warnings;

with 'Krawfish::Compile';

# This will sort the incoming results using a heap
# and the sort criteria.
# The priority queue will have n entries for n channels.
# When the list is full, the top entry is taken and the
# next entry of the channel of the top entry is enqueued.
#
# This may be less efficient than a dynamic
# mergesort, but for the moment, it's way simpler.

# TODO:
#   Add a timeout! Just in case ...!

# TODO:
#   Merge warnings, errors, messages!

# TODO:
#   Introduce max_rank_ref!

# TODO:
#   This may use a concurrent priorityqueue

# May be renamed to
# - Krawfish::MultiSegment::*
# - Krawfish::MultiNodes::*


use constant DEBUG => 0;


# Constructor
sub new {
  my $class = shift;

  # top_k, query, queries
  my $self = bless {
    @_
  }, $class;


  # Initialize match position
  $self->{pos} = 0;
  $self->{match} = undef;

  return $self unless $self->{top_k};

  # Add criterion comparation method
  $self->{prio} = Array::Queue::Priority->new(
    sort_cb => sub {
      my ($match_a, $match_b) = @_;

      # List of criteria
      my $crit_a = $match_a->[0]->sorted_by;
      my $crit_b = $match_b->[0]->sorted_by;

      # If the criterion is not defined on any level,
      # the entry is below any set entry
      return $crit_a->compare($crit_b);
    }
  );

  return $self;
};


# Get maximum frequency
sub max_freq {
  my $self = shift;
  my $max_freq;
  foreach (@{$self->{queries}}) {
    $max_freq += $_->max_freq
  };
  return $max_freq;
};


# Initially fill up the heap
sub _init {
  my $self = shift;

  return if $self->{init}++;

  if (DEBUG) {
    print_log('cmp_node', 'Initialize node response');
  };

  # Priority queue if sorting is required, per default with size $n
  my $prio = $self->{prio};

  my $i = 0;
  my $n = scalar @{$self->{queries}};

  # Iterate over all segments - either for grouping
  # or (in case of sorting) until the prio is full
  #
  # TODO:
  #   This needs to be done in parallel, as the initial
  #   querying (+ sorting) can take quite a lot of time!
  for (my $i = 0; $i < $n; $i++) {

    # Get query from segment
    my $seg_q = $self->{queries}->[$i];

    # Do grouping!
    unless ($prio) {

      if (DEBUG) {
        print_log('cmp_node', "Finalize query at channel $i");
      };

      # Search through all results
      $seg_q->finalize;
      next;
    };

    # There is a next item from the segment
    if ($seg_q->next) {

      if (DEBUG) {
        print_log('cmp_node', "Init query at channel $i");
      };

      # Enqueue and remember the segment/channel
      # TODO: enqueue
      $prio->add([$seg_q->current_match, $i]);

      if (DEBUG) {
        print_log('cmp_node', "Added match " . $seg_q->current_match->to_string);
      };
    }

    # No next segment - remove segment from query processing
    else {

      if (DEBUG) {
        print_log('cmp_node', "Remove query at channel $i");
      };

      # Remove segment query
      splice(@{$self->{queries}}, $i, 1);
      # segment list is shortened
      $i--;
      $n--;
    };
  };

  return unless $self->{prio};

  # Resize the priority queue
  # $prio->size($n);

  if (DEBUG) {
    print_log(
      'cmp_node',
      'Array: ' . join(',', map { $_->[0]->to_string } @{$prio->queue})
    );
  };

  # $self->{prio} = $prio;
};


# Get next match
sub next {
  my $self = shift;

  $self->_init;

  # There is no next
  return if !$self->{prio} || $self->{pos} > $self->{top_k} -1;

  # Get next match from list
  # TODO: dequeue
  my $entry = $self->{prio}->remove;

  # No more entries
  unless ($entry) {

    # Prevent further requests
    $self->{pos} = $self->{top_k} + 1;
    $self->{match} = undef;
    return;
  };

  # Set match
  $self->{match} = $entry->[0];

  # Get channel
  my $channel = $self->{queries}->[$entry->[1]];

  # If the channel has more entries to come,
  # add them to the priority queue
  if ($channel->next) {
    $self->{prio}->add([$channel->current_match, $entry->[1]]);
  };

  if (DEBUG) {
    print_log(
      'cmp_node',
      'Array: ' . join(',', map { $_->[0]->to_string } @{$self->{prio}->queue})
    );
  };

  $self->{pos}++;
  return 1;
};


# Return current match
sub current_match {
  return $_[0]->{match};
};


# Get merged result match
# TODO:
#   May not be necessary
sub compile {
  my $self = shift;

  $self->_init;

  my $result = $self->result;

  print_log('cmp_node','Compile result') if DEBUG;

  my $k = $self->{top_k};

  # Get next match from list
  # TODO: dequeue
  while ($k-- > 0) {
    my $entry = $self->{prio}->remove;

    # No more entries
    last unless $entry;

    $result->add_match($entry->[0]);

    # Get channel
    my $channel = $self->{queries}->[$entry->[1]];

    # If the channel has more entries to come,
    # add them to the priority queue
    if ($channel->next) {
      $self->{prio}->add(
        [$channel->current_match, $entry->[1]]
      );
    };
  };

  # Because all queries were sorted on a first pass,
  # there is no need to next() to the end for aggregation

  # Merge all aggregation
  $self->aggregate;

  return $result;
};


# Group data
sub group {
  my $self = shift;

  $self->_init;

  if (DEBUG) {
    print_log('cmp_node', 'Group data');
  };

  my $result = $self->result;

  if (DEBUG && $result->{group}) {
    print_log('cmp_node', 'Group is already done is already done');
  };

  # Aggregation already collected
  return $result if $result->group;

  # Iterate over all queries
  foreach my $seg_q (@{$self->{queries}}) {

    # Check for compilation role
    if (Role::Tiny::does_role($seg_q, 'Krawfish::Compile::Segment::Group')) {
      if (DEBUG) {
        print_log('cmp_node', 'Add result from ' . ref($seg_q));
      };

      # Merge aggregations
      my $group = $seg_q->group;

      if (DEBUG) {
        use Data::Dumper;
        print_log('cmp_node', 'Merge result: ' . ref($group) . ':' . $group->to_string);
      };

      # Merge group
      $result->merge_group($group);

      if (DEBUG) {
        print_log('cmp_node', 'Groups merged');
      };
    };
  };

  return $result;
};


# Get aggregation data only
sub aggregate {
  my $self = shift;

  $self->_init;

  if (DEBUG) {
    print_log('cmp_node', 'Aggregate data');
  };

  my $result = $self->result;

  if (DEBUG && @{$result->{aggregation}}) {
    print_log('cmp_node', 'Aggregation is already done');
  };

  # Aggregation already collected
  return $result if @{$result->{aggregation}};

  # Iterate over all queries
  foreach my $seg_q (@{$self->{queries}}) {

    # Check for compilation role
    if (Role::Tiny::does_role($seg_q, 'Krawfish::Compile::Segment')) {
      if (DEBUG) {
        print_log('cmp_node', 'Add result from ' . ref($seg_q));
      };

      # Merge aggregations
      my $aggregate = $seg_q->aggregate;
      if (DEBUG) {
        use Data::Dumper;
        print_log('cmp_node', 'Merge result ' . $aggregate->to_string);
      };
      $result->merge_aggregation($aggregate);

      if (DEBUG) {
        print_log('cmp_node', 'Result merged');
      };
    };
  };

  return $result;
};


# Prefetch final results
sub prefetch {
  # TODO:
  #   In case there are enrich methods,
  #   it can be beneficial to enrich the first x matches before
  #   the cluster resend the request to the nodes and the segments.
  #   so - the node may send the enrich request to the segments
  #   after the last successfull current_match with a certain number
  #   of matches to prefetch. When this is done, the segments
  #   can go through the top X results and prefetch snippets
  #   etc. while the node and the cluster is busy merging the result.
  ...
};


# stringification
sub to_string {
  my ($self, $id) = @_;
  my $str = 'node(';
  $str .= join(';', map { $_->to_string($id) } @{$self->{queries}});
  $str .= ')';
};


1;


__END__
