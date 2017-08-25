package Krawfish::Result::Segment::Sort::Sample;
use Krawfish::Log;
use strict;
use warnings;

# https://en.wikipedia.org/wiki/Reservoir_sampling
# https://webkist.wordpress.com/2008/10/01/reservoir-sampling-in-perl/
# https://blogs.msdn.microsoft.com/spt/2008/02/05/reservoir-sampling/

# A. Anagnostopoulos, A. Z. Broder, and D. Carmel. Sampling search-engine results. In Proc. of the Fourteenth International World Wide Web Conference, Chiba, Japan, 2005. ACM Press.


# WARNING:
#   Sorting does not respect current_match of any nested query, that's why
#   sorting is always separated from enriching!

use constant DEBUG => 1;

# Create a sample sort of k elements in the list
sub new {
  my $class = shift;
  bless {
    query     => shift,
    n         => shift, # Size of the sample
    k         => 0,     # Items already seen
    reservoir => [],
    current => undef
  }, $class;
};


sub max_freq {
  my $self = shift;
  my $n = $self->{query}->max_freq;
  $n = $n < $self->{n} ? $n : $self->{n};
  return $n;
};

# Initialize reservoir
sub _init {
  my $self = shift;

  return if $self->{k};

  if (DEBUG) {
    print_log('r_s_sample', 'Initialize sampling, meaning iterate over all items');
  };

  while ($self->{query}->next) {

    # Seen next item
    $self->{k}++;

    if (DEBUG) {
      print_log('r_s_sample', 'Found item ' . $self->{k});
    };

    # The reservoir is not filled up yet
    if ($self->{k} <= $self->{n}) {

      if (DEBUG) {
        print_log('r_s_sample', 'Add item ' . $self->{k} . ' to reservoir');
      };

      # Add current match to reservoir
      my $current = $self->{query}->current;
      push @{$self->{reservoir}}, $current;
    }

    # Check if the item should replace another item in the reservoir
    elsif (rand(1) <= ($self->{n}/$self->{k})) {

      my $item = int(rand($self->{n}));

      if (DEBUG) {
        print_log('r_s_sample', $self->{n} . ' == ' . scalar @{$self->{reservoir}});
        print_log('r_s_sample', "Overwrite item $item with item " . $self->{k});
      };

      # Replace random match in reservoir
      my $current = $self->{query}->current;

      # TODO:
      #   Check if $self->{n} is here equivalent to scalar @{$self->{reservoir}}
      $self->{reservoir}->[$item] = $current;
    }

    elsif (DEBUG) {
      print_log('r_s_sample', 'Ignore item ' . $self->{k});
    };
  };

  return;
};


# Move to next item
sub next {
  my $self = shift;

  # Fill reservoir
  $self->_init;

  # Get match from reservoir
  my $current = shift @{$self->{reservoir}};

  # There is no more match in reservoir
  unless ($current) {
    $self->{current} = undef;
    return;
  };

  # Set current match
  $self->{current} = $current;
  return 1;
};


sub current {
  $_[0]->{current};
};


sub match_from_query {
  ...
};


sub current_match {
  my $self = shift;
  my $current = $self->current or return;
  my $match = Krawfish::Posting::Match->new(
    doc_id  => $current->doc_id,
    start   => $current->start,
    end     => $current->end,
    payload => $current->payload,
  );

  if (DEBUG) {
    print_log('sort_sample', 'Current match is ' . $match->to_string);
  };

  return $match;
};

sub to_string {
  'sample(' . $_[0]->{n} . ':' . $_[0]->{query}->to_string . ')';
};


1;
