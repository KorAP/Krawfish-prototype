package Krawfish::Meta::Segment::SortAfter;
use parent 'Krawfish::Meta::Segment::Bundle';
use Data::Dumper;
use Krawfish::Log;
use strict;
use warnings;

# This Sorter is similar to
# Krawfish::Meta::Segment::Sort,
# But it already expects sorted, bundled postings,
# does not support $max_rank_ref
# (because all matches are already retrieved)
# and immediately stops, when top_k is reached.
#
# That also means, this does all the work in next_bundle()
# instead of init().


use constant {
  DEBUG   => 1,
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

  my $max_rank_ref = \(my $max_rank = $segment->max_rank);

  # Create initial priority queue
  # The priority queue may better be a bundle-based queue,
  # so each element has a size() attribute to tell how many matches are in there
  my $queue = Krawfish::Util::PriorityQueue::PerDoc->new(
    $top_k,
    $max_rank_ref
  );

  if (DEBUG) {
    print_log('sort_after', 'Initiate follow up sort');
  };

  bless {
    query    => $query,
    segment  => $segment,
    top_k    => $top_k,
    sort     => $sort,
    max_rank => $segment->max_rank,
    count    => 0 # number of (bundled) matches already served
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
  if ($self->{count} > $self->{top_k}) {
    return;
  }

  # There are sorted bundles on the buffer
  if ($self->{buffer} && @{$self->{buffer}}) {

    # This is also a bundle
    $self->{current_bundle} = shift(@{$self->{buffer}})->[VALUE];

    # Move forward by the length of the bundle
    $self->{count} += $self->{current_bundle}->size;

    # Fine
    return 1;
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
    ($self->{current_bundle}) = $next_bundle->unbundle;
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
    $self->{top_k} - $self->{count},
    $max_rank_ref
  );

  # Unbundle bundle and go through matches
  # TODO:
  #   This should be an iterator
  foreach my $posting ($next_bundle->unbundle) {

    if (DEBUG) {
      print_log('sort_after', 'Get next posting from ' . $self->{query}->to_string);
    };

    # Get stored rank
    $rank = $sort->rank_for($posting->doc_id);

    # TODO:
    #   Support next_doc() and preview_doc_id()
    #
    #        if ($rank > $$max_rank_ref) {
    #          # Document is irrelevant
    #          $match = undef;
    #
    #          if (DEBUG) {
    #            print_log('sort', 'Move to next doc');
    #          };
    #
    #          # Skip to next document
    #          $query->next_doc;
    #          CORE::next;
    #        };

    $queue->insert([$rank, 0, $posting, $posting->matches]);
    # 4. Push to buffer
  };

  my $array = $queue->reverse_array;

  print_log('sort_after', 'Get list ranking of ' . Dumper($array)) if DEBUG;

  # This is also a bundle
  $self->{current_bundle} = shift(@{$array})->[VALUE];

  print_log('sort_after', 'New current bundle is ' . $self->{current_bundle}->to_string) if DEBUG;

  $self->{buffer} = $array;
};


sub current_bundle {
  return $_[0]->{current_bundle};
};


# point to matches in the current bundle!
sub current_match {
  ...
};


sub to_string {
  my $self = shift;
  my $str = 'sort(';
  $str .= $self->{sort}->to_string;
  $str .= ',0-' . $self->{top_k} if $self->{top_k};
  $str .= ':' . $self->{query}->to_string;
  return $str . ')';
};

1;
