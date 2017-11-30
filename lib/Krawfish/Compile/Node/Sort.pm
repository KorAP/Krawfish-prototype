package Krawfish::Compile::Node::Sort;
use Krawfish::Util::Heap;
use strict;
use warnings;

# This will sort the incoming results using a heap
# and the sort criteria.
# The priority queue will have n entries for n channels.
# When the list is full, the top entry is taken and the
# next entry of the channel of the top entry is enqueued.

# This may be less efficient than a dynamic
# mergesort, but for the moment, it's way simpler.

# TODO:
#   Instead of using a mergesort approach, this may
#   use a concurrent priorityqueue instead.

# TODO:
#   May need to return Krawfish::Koral::Result::Match
#   with a 'sorted_by' array.
#   Instead of next() followed by current(), this should use
#   next_current() and - for matches - next_match()

sub new {
  my $class = shift;
  my $self = bless {
    query => shift,
    sort => shift,
    top_k => shift
  }, $class;

  $self->{heap} = Krawfish::Util::Heap->new($self->{top_k});

  # Add criterion comparation method here
  $self->{heap}->sort_by(
    sub {
      my ($obj_a, $obj_b) = @_;

      # List of criteria
      my $criterion_a = $obj_a->{criterion};
      my $criterion_b = $obj_b->{criterion};

      for (my $i = 0; $i < @{$criterion_a}; $i++) {
        if ($criterion_b->[$i]) {
          return 1;
        };
        if ($criterion_a->[$i] < $criterion_b->[$i]) {
          return -1;
        }
        elsif ($criterion_a->[$i] > $criterion_b->[$i]) {
          return 1;
        };
      };
      return -1;
    }
  );

  return $self;
};


sub to_string {
  my $self = shift;
  return 'sort(' .
    join(',', map { $_->to_string }
         @{$self->{sort}}) . ':' . $self->{query}->to_string . ')';
};


# Process one tail
sub process_tail {
  my ($self, $tail) = @_;

  # Iterate over all matches
  foreach my $match (@$tail) {

    # Enqueue as long as the list isn't full
    unless ($self->{heap}->enqueue($match)) {
      last;
    };
  };

  $self->{query}->process_tail($tail);
};

# TOD:
#   This should probably merge all aggregation results
#   directly in Krawfish::Koral::Result::*
sub process_aggregates {
  ...
};


sub to_result {
  ...
};



1;
