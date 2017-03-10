package Krawfish::Util::PriorityQueue::PerDoc;
use parent 'Krawfish::Util::PrioritySort';
use warnings;
use Krawfish::Log;

# TODO: Probably rename from IN_DOC to IN_COLL

use constant {
  DEBUG => 1,
  RANK => 0,
  SAME => 1,
  VALUE => 2,
  IN_DOC => 3,
  IN_DOC_COMPLETE => 4
};

# Construct new HEAP structure
sub new {
  my $class = shift;
  my ($top_k, $max_rank_ref) = @_;
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

# TODO: May accept rank, in_doc, value instead of nodes
# sub insert;

# Increment match count
sub incr {
  my ($self, $node) = @_;
  $self->{match_count} += $node->[IN_DOC];
};


# decrement match count
sub decr {
  my ($self, $node) = @_;
  $self->{match_count} -= $node->[IN_DOC];
};


sub incr_top_duplicate {
  my ($self, $node) = @_;
  $self->{array}->[0]->[SAME]++;
  $self->{array}->[0]->[IN_DOC_COMPLETE] += $node->[IN_DOC];
};


# Return tree stringification
sub to_tree {
  my $self = shift;
  return
    join('', map {
    '[' . $_->[RANK] .
      ($_->[SAME] ? ':' . $_->[SAME] : '') .
      ($_->[IN_DOC] ? 'x' . $_->[IN_DOC] : '') .
      ']'
  } @{$self->{array}}[0..$self->{index}-1]);
};

sub top_identical_matches {
  my $top = $_[0]->{array}->[0];

  if ($top->[SAME] > 1) {
    warn 'Undefined yet!';
  }
  else {
    return $top->[IN_DOC]
  };

  # TODO:
  # - Go through all same nodes and get
  #   the sum for all per_doc values.
  #
  # $top->[SAME] + $top->[PER_DOC];
  # Of course this should be stored in a separated value,
  # But this would mean, we need another field per node
  #
  # TODO: Cache the value!
  ...
};


1;


__END__


sub mark_top_duplicates {
  ...
};


1;
