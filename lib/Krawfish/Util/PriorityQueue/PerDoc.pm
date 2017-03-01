package Krawfish::Util::PriorityQueue::PerDoc;
use parent 'Krawfish::Util::PrioritySort';
use warnings;
use Krawfish::Log;

use constant {
  DEBUG => 0,
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

sub insert {
  my ($self, $node) = @_;

  # Rank is beyond useful
  if ($node->[RANK] > ${$self->{max_rank_ref}}) {
    print_log('prio', "Rank is larger than max rank") if DEBUG;
    return;
  };

  if ($self->enqueue($node)) {
    $self->{match_count} += $node->[IN_DOC];
  };
  
  return 1;
};


sub incr_top_duplicate {
  my ($self, $node) = @_;
  $self->{array}->[0]->[SAME]++;
  $self->{array}->[0]->[IN_DOC_COMPLETE] += $node->[IN_DOC];
};



1;

__END__



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


sub to_tree;

sub mark_top_duplicates {
  ...
};


1;
