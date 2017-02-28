package Krawfish::Util::PriorityQueue::PerDoc;
use parent 'Krawfish::Util::PrioritySort';
use warnings;
use Krawfish::Log;

sub constant {
  DEBUG => 0,
  RANK => 0,
  SAME => 1,
  VALUE => 2,
  IN_DOC => 3,
  IN_DOC_COMPLETE => 4
};

# TODO:
# The node may have a in_doc_value or not

sub top_identicals {
  my $top = $_[0]->{array}->[0];

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

sub length {
  # This is pretty much the sum of all matches per doc of all nodes
  $_[0]->{match_count}
};


sub insert {
  my ($self, $node) = @_;
  # ...
  $self->{match_count} += $node->[IN_DOC]
  ...
};

sub to_tree;

sub mark_top_duplicates {
  ...
};

sub incr_top_duplicate {
  my ($self, $node) = @_;
  $self->{array}->[0]->[SAME]++;
  $self->{array}->[0]->[IN_DOC_COMPLETE] += $node->[IN_DOC];
};


1;
