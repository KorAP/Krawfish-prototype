package Krawfish::Result::Sort::InitRank;
use Krawfish::Util::PrioritySort;
use Krawfish::Log;
use Data::Dumper;
use strict;
use warnings;

use constant DEBUG => 1;

sub new {
  my $class = shift;
  my %param = @_;

  my $query = $param{query};
  my $field_rank  = $param{field_rank};

  my $top_k = $param{top_k};
  my $offset = $param{offset};
  my $max_rank_ref = $param{max_rank_ref};
  my $desc = $param{desc} ? 1 : 0;

  # Create priority queue
  my $queue = Krawfish::Util::PrioritySort->new($top_k, $max_rank_ref);

  return bless {
    field_rank => $field_rank,
    desc => $desc,
    query => $query,
    queue => $queue,
    list => undef,
    pos => -1
  }, $class;
};


# Init queue
sub _init {
  my $self = shift;

  return if $self->{init}++;

  my $field_rank = $self->{field_rank};

  my $max;
  # Get maximum rank if descending order
  if ($self->{desc}) {
    $max = $field_rank->max;
  };

  my $query = $self->{query};
  my $queue = $self->{queue};

  # Pass through all queries
  while ($query->next) {

    if (DEBUG) {
      print_log('i_sort', 'Get next posting from ' . $query->to_string);
    };

    # Clone record
    my $record = $query->current->clone;

    # Get stored rank
    my $rank = $field_rank->get($record->doc_id);

    # Revert if maximum rank is set
    $rank = $max - $rank if $max;

    # Insert into priority queue
    $queue->insert($rank, $record);
  };

  # Get the rank reference
  $self->{list} = $queue->reverse_array;
  $self->{length} = $queue->length;
};


sub next {
  my $self = shift;
  $self->_init;
  if ($self->{pos}++ < $self->{length}) {
    return 1;
  };
  return;
};

sub current {
  my $self = shift;
  # 2 is the index of the value
  print_log('i_sort', 'Get match from index ' . $self->{pos}) if DEBUG;

  return $self->{list}->[$self->{pos}]->[2];
};

# This returns an additional data structure with key/value pairs
# in sorted order to document the sort criteria.
# Like: [[class_1 => 'cba'], [author => 'Goethe']]...
# This is beneficial for the cluster-merge-sort
sub current_sort;

sub to_string {
  my $self = shift;
  my $str = 'initRankSort(';
  $str .= $self->{desc} ? '^' : 'v';
  $str .= ',' . $self->{field} . ':';
  $str .= $self->{query}->to_string;
  return $str . ')';
};


1;
