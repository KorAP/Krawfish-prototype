package Krawfish::Compile::Segment::SortAfter;
use Data::Dumper;
use Krawfish::Log;
use strict;
use warnings;
use Role::Tiny;

with 'Krawfish::Compile::Segment::Sort';

# TODO:
#   Split this up, so it can be composed
#   using the same roles as ::Sort,
#   by changing the get_bundle_from_buffer
#   method.

# This sorting query is similar to
# Krawfish::Compile::Segment::Sort,
# But it already expects sorted, bundled postings,
# does not support $max_rank_ref
# (because all matches are already retrieved),
# and immediately stops, when top_k is reached.
#
# That also means, this does all the work in next_bundle()
# instead of init().


use constant {
  DEBUG   => 0,
  RANK    => 0,
  SAME    => 1,
  VALUE   => 2,
  MATCHES => 3
};


# Constructor
sub new {
  my $class = shift;
  my %param = @_;

  my $query    = $param{query};
  my $segment  = $param{segment};
  my $top_k    = $param{top_k};

  # This is the sort criterion
  my $sort     = $param{sort};

  $top_k //= $segment->max_rank;

  if (DEBUG) {
    print_log('sort_after', 'Initiate follow up sort');
  };

  bless {
    query       => $query,
    segment     => $segment,
    top_k       => $top_k,
    sort        => $sort,
    max_rank    => $segment->max_rank,
    pos_in_sort => 0, # Current position in sorted heap
    pos         => 0  # Number of (bundled) matches already served
  }, $class;
};


# Move to next bundle
sub next_bundle {
  my $self = shift;

  if (DEBUG) {
    print_log('sort_after', 'Move to next bundle');
  };

  $_[0]->{current_bundle} = undef;

  # Already served enough
  if ($self->{pos} > $self->{top_k}) {
    return;
  }

  # There are sorted bundles on the buffer
  if ($self->{buffer}) {

    # The buffer is not exceeded yet
    if ($self->{pos_in_sort} < @{$self->{buffer}}) {

      $self->{current_bundle} = $self->get_bundle_from_buffer;

      # Get the number of matches in the bundle
      $self->{pos} += $self->{current_bundle}->matches;

      # Fine
      return 1;
    };

    # Buffer is exceeded - reset
    $self->{buffer} = undef;
    $self->{pos_in_sort} = 0;
  };

  # Get a new bundle from the nested query
  unless ($self->{query}->next_bundle) {
    return;
  };

  if (DEBUG) {
    print_log('Get next bundle from ' . $self->{query}->to_string);
  };

  my $next_bundle = $self->{query}->current_bundle;

  # Next bundle is already sorted
  if ($next_bundle->size == 1) {

    # Do nothing
    $self->{current_bundle} = $next_bundle;
    return 1;
  };

  # Sort next bundle

  # This should probably check for a simpler sorting
  # algorithm for small data sets
  my $rank;
  my $sort = $self->{sort};
  my $max_rank_ref = \(my $max_rank = $self->{max_rank});

  if (DEBUG) {
    print_log('sort_after', 'Sort nested bundle');
  };

  # Create initial priority queue
  my $queue = Krawfish::Util::PriorityQueue::PerDoc->new(
    $self->{top_k} - $self->{pos},
    $max_rank_ref
  );

  # Unbundle bundle and go through matches
  for (my $i = 0; $i < $next_bundle->size; $i++) {

    # Get item from list
    my $posting = $next_bundle->item($i);

    if (DEBUG) {
      print_log('sort_after', 'Get next posting from ' . $self->{query}->to_string);
    };

    # Get stored rank
    $rank = $sort->rank_for($posting->doc_id);

    # Checking for $$max_rank_ref is not useful here,
    # as the bundles are already bundled and skipping bundles
    # using next_doc() and preview_doc_id() is not beneficial.

    $queue->insert([$rank, 0, $posting, $posting->matches]);
  };

  # Get the sorted array (which has still the ranking structure etc.)
  my $array = $queue->reverse_array;

  print_log('sort_after', 'Get list ranking of ' . Dumper($array)) if DEBUG;

  if (DEBUG) {
    print_log(
      'sort_after',
      'New current bundle is ' . $self->{current_bundle}->to_string
    );
  };

  # Store the sorted bundle in the buffer
  $self->{buffer} = $array;

  # Set current bundle
  $self->{current_bundle} = $self->get_bundle_from_buffer;

  # Remember the number of entries
  $self->{pos} += $self->{current_bundle}->matches;
  return 1;
};


# Clone query
sub clone {
  my $self = shift;
  __PACKAGE__->new(
    query   => $self->{query}->clone,
    segment => $self->{segment},
    top_k   => $self->{top_k},
    sort    => $self->{sort}
  );
};


# Stringification
sub to_string {
  my $self = shift;
  my $str = 'sort(';
  $str .= $self->{sort}->to_string;
  $str .= ',0-' . $self->{top_k} if $self->{top_k};
  $str .= ':' . $self->{query}->to_string;
  return $str . ')';
};

1;
