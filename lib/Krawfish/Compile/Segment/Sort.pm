package Krawfish::Compile::Segment::Sort;
use Krawfish::Util::String qw/squote/;
use Krawfish::Util::Constants qw/MAX_TOP_K/;
use Krawfish::Util::PriorityQueue::PerDoc;
use Krawfish::Koral::Result::Match;
use Krawfish::Posting::Bundle;
use Krawfish::Log;
use Data::Dumper;
use strict;
use warnings;
use Role::Tiny;

with 'Krawfish::Compile::Segment::Sort::Criterion';
with 'Krawfish::Compile::Segment::BundleDocs';
with 'Krawfish::Compile::Segment';

# This is the general sorting implementation based on ranks.
#
# It establishes a top-k HeapSort approach and expects bundles
# of matches to sort by a rank. It returns bundles.
#
# A given segment-wide $max_rank_ref can be used to ignore documents
# during search in a sort filter.

# TODO:
#   Split up the roles for better compositionality

# TODO:
#   Currently this is limited to fields and works different to subterms.
#   So this may need to be renamed to Sort/ByField and Sort/ByFieldAfter.

# TODO:
#   It's possible that fields return a rank of 0, indicating that
#   the field does not exist for the document.
#   They will always be sorted at the end.
#   In that case these fields have to be looked up, in case they are
#   potentially in the result set (meaning they are ranked before/after
#   the last accepted rank field). If so, they need to be remembered.
#   After a sort turn, the non-ranked fields are sorted in the ranked
#   fields. The field can be reranked any time.

# TODO:
#   Ranks should respect the ranking mechanism of FieldsRan,
#   where only even values are fine and odd values need
#   to be sorted in a separate step (this is still open for discussion).

# TODO:
#   It may be beneficial to have the binary heap space limited
#   and do a quickselect whenever the heap is full - to prevent full
#   sort, see
#   http://lemire.me/blog/2017/06/14/quickselect-versus-binary-heap-for-top-k-queries/
#   https://plus.google.com/+googleguava/posts/QMD74vZ5dxc
#   although
#   http://lemire.me/blog/2017/06/21/top-speed-for-top-k-queries/
#   says its irrelevant


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

  if (DEBUG) {
    print_log('sort', 'Initiate sort object');
  };

  # TODO:
  #   Check for mandatory parameters
  #
  my $query = $param{query};

  unless (Role::Tiny::does_role($query, 'Krawfish::Compile::Segment::Bundle')) {
    warn 'The query is no bundled query';
    return;
  };

  my $segment  = $param{segment};
  my $top_k    = $param{top_k};

  # This is the sort criterion
  my $criterion = $param{criterion};

  # Set top_k if not yet set
  # - to be honest, heap sort is probably not the
  # best approach for a full search
  $top_k //= MAX_TOP_K;

  # The maximum ranking value may be used
  # by outside filters to know in advance,
  # if a document can't be part of the result set
  my $max_rank_ref;
  if (defined $param{max_rank_ref}) {

    # Get reference from definition
    $max_rank_ref = $param{max_rank_ref};
  }
  else {

    # Create a new reference
    $max_rank_ref = \(my $max_rank = $segment->max_rank);
  };

  # Create initial priority queue
  my $queue = Krawfish::Util::PriorityQueue::PerDoc->new(
    $top_k,
    $max_rank_ref
  );

  # Construct
  return bless {
    segment      => $segment,
    top_k        => $top_k,
    query        => $query,
    queue        => $queue,
    max_rank_ref => $max_rank_ref,
    max_rank     => $segment->max_rank,

    last_doc_id  => -1,

    criterion    => $criterion,

    buffer       => undef,
    pos_in_sort  => 0,

    # Default starts
    stack        => [],  # All lists on a stack
    sorted       => [],
    pos          => 0 # Number of matches already served
  }, $class;
};


# Initialize the sorting - this will do a full run!
sub _init {
  my $self = shift;

  # Result already initiated
  return if $self->{init}++;

  my $query = $self->{query};

  if (DEBUG) {
    print_log('sort', 'Initialize sort object');
  };

  # TODO:
  #   Make this work for terms as well!

  # TODO:
  #   This currently only works for fields,
  #   because it bundles document ids.
  #   The prebundling of documents may be
  #   done in a separated step.

  # Get maximum accepted rank from queue
  my $max_rank_ref = $self->{max_rank_ref};
  my $queue = $self->{queue};
  my $criterion = $self->{criterion};

  if (DEBUG) {
    print_log('sort', qq!Next Rank on field #! . $criterion->term_id);
  };

  # Store the last match buffered
  my ($match, $rank);

  # Init
  unless ($query->next_bundle) {
    print_log('sort', 'Nothing to sort');
    return;
  };

  # Pass through all queries
  while ($match = $query->current_bundle) {

    if (DEBUG) {
      print_log('sort', 'Get next posting from ' . $query->to_string);
    };

    # Get stored rank
    # TODO:
    #   Rank may already be set for level, e.g. by SortFilter
    $rank = $criterion->rank_for($match->doc_id);

    if (DEBUG) {
      print_log('sort', 'Rank for doc id ' . $match->doc_id . " is $rank");
      print_log('sort', "Check rank $rank against max rank " . $$max_rank_ref);
    };

    # Precheck if the match is relevant
    if ($rank > $$max_rank_ref) {

      # Document is irrelevant
      $match = undef;

      if (DEBUG) {
        print_log('sort', 'Move to next doc');
      };

      # Skip to next document
      $query->next_doc;
      CORE::next;
    };

    # Get current bundle
    my $bundle = $query->current_bundle;

    # Set level for doc bundle
    $bundle->rank(0 => $rank);

    # Insert bundle into priority queue with length information
    $queue->insert([$rank, 0, $bundle, $bundle->match_count]) if $bundle;

    if (DEBUG) {
      print_log('sort', 'Move to next bundle');
    };

    # Move to next bundle
    $query->next_bundle;
  };

  my $array = $queue->reverse_array;
  if (DEBUG && 0) {
    print_log('sort', 'Get list ranking of ' . Dumper($array));
  };

  if (DEBUG) {
    print_log(
      'sort',
      'First pass sorting finished',
      '###############################'
    );
  };

  # Get the rank reference (new);
  $self->{buffer} = $array;
};


# Clone query
sub clone {
  my $self = shift;
  __PACKAGE__->new(
    query   => $self->{query}->clone,
    segment => $self->{segment},
    top_k   => $self->{top_k},
    criterion => $self->{criterion},
    max_rank_ref => $self->{max_rank_ref}
  );
};


sub max_rank {
  $_[0]->{max_rank};
};


# The sorting level
# (relevant for enrichments of criteria)
sub level {
  0;
};


# Move to the next item in the bundled document list
# and create the next bundle
sub next_bundle {
  my $self = shift;

  # Initialize query - this will do a full run on the first field level!
  $self->_init;

  if ($self->{pos_in_sort} >= @{$self->{buffer}}) {
    if (DEBUG) {
      print_log('sort', 'No more elements in the priority array');
    };

    $self->{current_bundle} = undef;
    return;
  };

  if (DEBUG) {
    print_log('sort', 'Get current bundle from buffer');
  };

  # Set current bundle
  $self->{current_bundle} = $self->get_bundle_from_buffer;

  if (DEBUG) {
    print_log('sort', 'Current bundle is now ' . $self->{current_bundle}->to_string);
  };

  # Remember the number of entries
  $self->{pos} += $self->{current_bundle}->match_count;
  return 1;
};


# Get the top bundle from buffer
sub get_bundle_from_buffer {
  my $self = shift;

  # Iterate over the next elements with identical ranks
  my $pos = $self->{pos_in_sort};

  # Get the top entry
  my $top_bundle = $self->{buffer}->[$pos];

  if (DEBUG) {
    print_log(
      'sort',
      "Move to next bundle at $pos, which is " .
        $top_bundle->[VALUE]);
  };

  my $rank = $top_bundle->[RANK];

  if (DEBUG) {
    print_log(
      'sort',
      "Create new bundle from prio at $pos starting with " .
        $top_bundle->[VALUE]->to_string);
  };

  # Initiate new bundle
  my $new_bundle = Krawfish::Posting::Bundle->new($top_bundle->[VALUE]);

  $pos++;
  for (; $pos < @{$self->{buffer}}; $pos++) {
    $top_bundle = $self->{buffer}->[$pos];

    if (DEBUG) {
      print_log(
        'sort',
        'Check follow up from prio: ' . $top_bundle->[VALUE]->to_string
      );
    };

    # Add element to bundle
    if ($rank == $top_bundle->[RANK]) {

      if (DEBUG) {
        print_log('sort', "Both items have the same rank $rank");
      };

      unless ($new_bundle->add($top_bundle->[VALUE])) {
        warn 'Unable to add bundle to new bundle';
      };
    }

    # Stop
    else {
      last;
    };
  };

  # Get position
  $self->{pos_in_sort} = $pos;

  if (DEBUG) {
    print_log('sort', 'Return bundle is ' . $new_bundle->to_string);
  };

  return $new_bundle;
};


sub criterion {
  $_[0]->{criterion};
};


# Stringification
sub to_string {
  my $self = shift;
  my $str = 'sort(';
  $str .= $self->{criterion}->to_string;
  $str .= ',l=' . $self->level if $self->level;
  if ($self->{top_k} != MAX_TOP_K) {
    $str .= ',0-' . $self->{top_k};
  };
  $str .= ':' . $self->{query}->to_string;
  return $str . ')';
};


sub _string_array {
  my $array = shift;
  my $str = '';
  foreach (@$array) {
    $str .= '[';
    $str .= 'R:' . $_->[RANK] . ';';
    $str .= ($_->[SAME] ? 'S:' . $_->[SAME] . ';' : '');
    $str .= ($_->[MATCHES] ? 'M:' . $_->[MATCHES] : '');
    $str .= ']';
  };
  return $str;
};


1;

__END__
