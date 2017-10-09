package Krawfish::Compile::Segment::Sort::Simple;
use Krawfish::Log;
use strict;
use warnings;

warn 'NOT USED YET';

# This should be used fur subsequent
# sorting following the first pass

# May use insertion sort for small numbers
# of duplicates.

# This may very well be a PrioritySort,
# so initially there is a very simple
# querier that only add rank and same elements
# and subsequential they are ranked

sub new {
  my $class = shift;
  my %param = @_;

  my $query = $param{query};
  my $fields  = $param{fields};
  my $field  = $param{field};
  my $desc = $param{desc} ? 1 : 0;

  my $top_k = $param{top_k};

  return bless {
    field_rank => $fields->ranked_by($field),
    field => $field,
    desc => $desc,
    query => $query,
    queue => $queue,
    list => undef,
    pos => -1
  }, $class;
};

sub next {

  # TODO:
  #   In case the sorting before
  #   results in a very bad configuration
  #   (lots of duplicates in the final pos),
  #   choose a different strategy!

  my $field_rank = $self->{field_rank};

  my $max;
  # Get maximum rank if descending order
  if ($self->{desc}) {
    $max = $field_rank->max;
  };

  my $query = $self->{query};

  while ($query->next) {
    if (DEBUG) {
      print_log('s_sort', 'Get next posting from ' . $query->to_string);
    };

    # The rank is totally fine
    if ($query->duplicate_rank == 1) {
      $self->{pos} = 0;
      $self->{list} = [$query->current];
      return 1;
    }

    # The rank has many duplicates
    else {

      # Sort elements!
      my $elements = $query->duplicate_rank;
      for (1..$elements) {
        $query->next;

#        # Clone record
#        my $record = $query->current->clone;

      };
    };
  };
};
