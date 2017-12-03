package Krawfish::Compile::Node::Sort;
use Array::Queue::Priority;
use Krawfish::Util::Heap;
use Krawfish::Log;
use strict;
use warnings;

# Sort matches based on their criteria!

# This will sort the incoming results using a heap
# and the sort criteria.
# The priority queue will have n entries for n channels.
# When the list is full, the top entry is taken and the
# next entry of the channel of the top entry is enqueued.

# TODO:
#   Share result(), aggregate() and some other
#   methods/attributes with the compile-role!


# This may be less efficient than a dynamic
# mergesort, but for the moment, it's way simpler.

# TODO:
#   Instead of using a mergesort approach, this may
#   use a concurrent priorityqueue instead.


use constant DEBUG => 0;


# Constructor
sub new {
  my $class = shift;

  # top_k
  my $self = bless {
    @_
  }, $class;


  # Initialize match position
  $self->{pos} = 0;
  $self->{match} = undef;

  # Get query
  my $query = $self->{query};

  # Optimize query for segments
  my @segment_queries;
  foreach my $seg (@{$self->{segments}}) {
    my $segment_query = $query->optimize($seg);

    if (DEBUG) {
      print_log('c_n_sort', 'Add query ' . $segment_query->to_string . ' to merge');
    };

    # There are results expected
    if ($segment_query->max_freq != 0) {
      push @segment_queries, $segment_query;
    };
  };

  $self->{segment_queries} = \@segment_queries;

  # Add criterion comparation method here
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


# Initially fill up the heap
sub _init {
  my $self = shift;

  return if $self->{init}++;

  if (DEBUG) {
    print_log('c_n_sort', 'Initialize sorting queue');
  };

  my $i = 0;
  my $n = scalar @{$self->{segment_queries}};

  # Priority queue, per default with size $n
  my $prio = $self->{prio};

  # Iterate over all segments until the prio is full
  #
  # TODO:
  #   This needs to be done in parallel, as the initial
  #   querying (+ sorting) can take quite a lot of time!
  for (my $i = 0; $i < $n; $i++) {

    # Get query from segment
    my $seg_q = $self->{segment_queries}->[$i];

    # There is a next item from the segment
    if ($seg_q->next) {

      if (DEBUG) {
        print_log('c_n_sort', "Init query at channel $i");
      };

      # Enqueue and remember the segment/channel
      # TODO: enqueue
      $prio->add([$seg_q->current_match, $i]);

      if (DEBUG) {
        print_log('c_n_sort', "Added match " . $seg_q->current_match->to_string);
      };
    }

    # No next segment - remove segment from query processing
    else {

      if (DEBUG) {
        print_log('c_n_sort', "Remove query at channel $i");
      };

      # Remove segment query
      splice(@{$self->{segment_queries}}, $i, 1);
      # segment list is shortened
      $i--;
      $n--;
    };
  };

  # Resize the priority queue
  # $prio->size($n);

  if (DEBUG) {
    print_log(
      'c_n_sort',
      'Array: ' . join(',', map { $_->[0]->to_string } @{$prio->queue})
    );
  };

  $self->{prio} = $prio;
};


# Get next match
sub next {
  my $self = shift;

  $self->_init;

  # There is no next
  return if $self->{pos} > $self->{top_k} -1;

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
  my $channel = $self->{segment_queries}->[$entry->[1]];

  # If the channel has more entries to come,
  # add them to the priority queue
  if ($channel->next) {
    $self->{prio}->add([$channel->current_match, $entry->[1]]);
  };

  if (DEBUG) {
    print_log(
      'c_n_sort',
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

  print_log('c_n_sort','Compile result') if DEBUG;

  my $k = $self->{top_k};

  # Get next match from list
  # TODO: dequeue
  while ($k--) {
    my $entry = $self->{prio}->remove;

    # No more entries
    last unless $entry;

    $result->add_match($entry->[0]);

    # Get channel
    my $channel = $self->{segment_queries}->[$entry->[1]];

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


# Get aggregation data only
# TODO:
#   Identical with ::Compile
sub aggregate {
  my $self = shift;

  $self->_init;

  if (DEBUG) {
    print_log('c_n_sort', 'Aggregate data');
  };

  my $result = $self->result;

  # Iterate over all queries
  foreach my $seg_q (@{$self->{segment_queries}}) {

    # Check for compilation role
    if (Role::Tiny::does_role($seg_q, 'Krawfish::Compile')) {
      if (DEBUG) {
        print_log('c_n_sort', 'Add result from ' . ref($seg_q));
      };

      # Merge aggregations
      $result->merge_aggregation($seg_q->aggregate);
    };
  };

  return $result;
};



# Get result object
# TODO:
#   Identical with ::Compile
sub result {
  my $self = shift;
  if ($_[0]) {
    $self->{result} = shift;
    return $self;
  };
  $self->{result} //= Krawfish::Koral::Result->new;
  return $self->{result};
};


# stringification
sub to_string {
  my ($self, $id) = @_;
  my $str = 'nSort(';
  $str .= join(';', map { $_->to_string($id) } @{$self->{segment_queries}});
  $str .= ')';
};


1;


__END__
