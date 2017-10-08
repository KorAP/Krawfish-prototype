package Krawfish::Util::PriorityQueue::PerDoc;
use parent 'Krawfish::Util::PrioritySort';
use strict;
use warnings;
use Krawfish::Log;

# TODO: Simplify to not require max_rank_ref!

# TODO: Add reset method, so the PQ can be reused
#       in SortAfter!

# TODO: This currently only works with ranks,
#       it may be more beneficial to work with criteria.
#       So instead to compare ranks, a Criterion object will
#       compare arbitrary data in the "rank"-field

# TODO: Probably rename from IN_DOC to IN_COLL
# TODO: Probably rename to PriorityQueue::Bundle
# TODO: Turn reverse_array into an iterator

use constant {
  DEBUG       => 0,
  RANK        => 0,
  SAME        => 1,
  VALUE       => 2,
  MATCHES     => 3,
  MATCHES_ALL => 4
};


# Construct new HEAP structure
sub new {
  my $class = shift;
  my ($top_k, $max_rank_ref) = @_;

  if (DEBUG) {
    print_log('prio_doc', 'Initialize new prio');
  };

  my $self = bless {
    top_k        => $top_k,
    max_rank_ref => $max_rank_ref,
    array        => [],
    index        => 0,
    match_count  => 0
  }, $class;
};


sub length {
  # This is pretty much the sum of all matches per doc of all nodes
  $_[0]->{match_count};
};


# TODO: May accept rank, matches, value instead of nodes
# sub insert;

# Increment match count
sub incr {
  my ($self, $node) = @_;
  $self->{match_count} += $node->[MATCHES];
};


# decrement match count
sub decr {
  my ($self, $node) = @_;
  $self->{match_count} -= $node->[MATCHES];
};


sub incr_top_duplicate {
  my ($self, $node) = @_;
  return unless $self->{array}->[0];

  $self->{array}->[0]->[SAME]++;
  $self->{array}->[0]->[MATCHES_ALL] += $node->[MATCHES];
};


# Return tree stringification
sub to_tree {
  my $self = shift;
  return '(RANK:SAMExMATCHES) ' .
    join('', map {
    '[' . $_->[RANK] .
      ($_->[SAME] ? ':' . $_->[SAME] : '') .
      ($_->[MATCHES] ? 'x' . $_->[MATCHES] : '') .
      ']'
  } @{$self->{array}}[0..$self->{index}-1]);
};


# Returns the number of identical ranked matches
sub top_identical_matches {

  # Get top item
  my $top = $_[0]->{array}->[0] or return 0;

  # There are some equally ranked items in the heap
  if ($top->[SAME] > 1) {

    # Return the sum of all identically ranked matches
    return $top->[MATCHES_ALL];
  };

  # Return the number of matches
  return $top->[MATCHES] // 1;
};


sub mark_top_duplicates {
  my $self = shift;
  my ($count_same, $count_matches) = (0, 0);
  my $array = $self->{array};

  return if $self->{array}->[0]->[MATCHES_ALL];

  # Iterate over all same nodes
  $self->on_same_top(
    0,
    sub {
      my $node_i = $_[0];
      $count_same++;
      $count_matches += $array->[$node_i]->[MATCHES];
    }
  );
  if ($count_same) {
    $array->[0]->[SAME] = $count_same;
    $array->[0]->[MATCHES_ALL] = $count_matches;
    if (DEBUG) {
      print_log(
        'prio_doc',
        "Mark top element with count $count_same and all $count_matches"
      );
    };
  };
};


1;


__END__
