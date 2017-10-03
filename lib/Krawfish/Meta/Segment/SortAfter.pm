package Krawfish::Meta::Segment::SortAfter;
use parent 'Krawfish::Meta';
use strict;
use warnings;

# This Sorter is similar to
# Krawfish::Meta::Segment::Sort,
# But it already expects sorted, bundled postings,
# does not support $max_rank_ref
# (because all matches are already retrieved)
# and immediately stops, when top_k is reached.
#
# That also means, this respects next etc.
# and doesn't do all the work in init() phase.

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

  bless {
    query   => $query,
    segment => $segment,
    top_k   => $top_k,
    sort    => $sort,
    count   => 0 # number of (bundled) matches already served
  }, $class;
};


# Move to next bundle
sub next {
  my $self = shift;

  # Already served enough
  if ($self->{count} > $self->{top_k}) {
    $_[0]->{current_bundle} = undef;
    return;
  }

  # There are sorted bundles on the buffer
  if (@{$self->{buffer}}) {

    # This is also a bundle
    $self->{current_bundle} = shift @{$self->{buffer}};

    # Move forward by the length of the bundle
    $self->{count} += $self->{current_bundle}->size;

    # Fine
    return 1;
  };

  # Get a new bundle from the nested query
  if ($self->{query}->next) {
    my $next_bundle = $self->{query}->current_bundle;

    # 1. Split the bundle
    # 2. Sort
    # 3. add sorting criterion
    # 4. Push to buffer
  };
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
