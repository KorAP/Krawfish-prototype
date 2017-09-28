package Krawfish::Meta::Segment::Sort;
use parent 'Krawfish::Meta';
use Krawfish::Util::String qw/squote/;
use Krawfish::Util::PriorityQueue::PerDoc;
use Krawfish::Koral::Result::Match;
use Krawfish::Posting::Bundle;
use Krawfish::Log;
use Data::Dumper;
use strict;
use warnings;

# This is the general sorting implementation based on ranks.

use constant {
  DEBUG   => 1,
  RANK    => 0,
  SAME    => 1,
  VALUE   => 2,
  MATCHES => 3
};


# TODO:
#   It's possible that fields return a rank of 0, indicating that
#   the field does not exist for the document.
#   They will always be sorted at the end.

# TODO:
#   Ranks should respect the ranking mechanism of FieldsRank and
#   TermRank, where only even values are fine and odd values need
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

# TODO:
#   It is necessary to add the sorting criteria.


sub max_freq {
  $_[0]->{query}->max_freq;
};


# Constructor
sub new {
  my $class = shift;
  my %param = @_;

  # TODO:
  #   Check for mandatory parameters
  my $query    = $param{query};
  my $segment  = $param{segment};
  my $top_k    = $param{top_k};

  # This is the sort criterion
  my $sort     = $param{sort};

  # Set top_k if not yet set
  # - to be honest, heap sort is probably not the
  # best approach for a full search
  $top_k //= $segment->last_doc;

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
    $max_rank_ref = \(my $max_rank = $segment->last_doc);
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

    # TODO:
    #   Rename to criterion
    sort         => $sort,

    # Default starts
    stack        => [],  # All lists on a stack
    sorted       => [],
    pos          => 0
  }, $class;
};


# Initialize the sorting - this will do a full run!
sub _init {
  my $self = shift;

  # Result already initiated
  return if $self->{init}++;

  my $query = $self->{query};

  # TODO:
  #   Make this work for terms as well!

  # TODO:
  #   This currently only works for fields,
  #   because it bundles document ids.
  #   The prebundling of documents may be
  #   done in a separated step.

  # Get maximum accepted rank from queue
  my $max_rank_ref = $self->{max_rank_ref};

  my $last_doc_id = -1;
  my $queue = $self->{queue};

  my $sort = $self->{sort};

  # Store the last match buffered
  my $match;

  if (DEBUG) {
    print_log('p_sort', qq!Next Rank on field #! . $sort->term_id);
  };

  my $rank;

  # Pass through all queries
  while ($match || ($query->next && ($match = $query->current))) {

    if (DEBUG) {
      print_log('p_sort', 'Get next posting from ' . $query->to_string);
    };

    # Get stored rank
    $rank = $sort->rank_for($match->doc_id);

    if (DEBUG) {
      print_log('p_sort', 'Rank for doc id ' . $match->doc_id . " is $rank");
    };

    # Precheck if the match is relevant
    if ($rank > $$max_rank_ref) {

      # Document is irrelevant
      $match = undef;
      next;
    };

    # Create new bundle of matches
    my $bundle = Krawfish::Posting::Bundle->new($match->clone);

    # Remember doc_id
    $last_doc_id = $match->doc_id;
    $match = undef;

    # Iterate over next queries
    while ($query->next) {

      # New match should join the bundle
      if ($query->current->doc_id == $last_doc_id) {

        # Add match to bundle
        $bundle->add($query->current);
      }

      # New match is new
      else {

        # Remember match for the next tome
        $match = $query->current;
        last;
      };
    };

    # Insert into priority queue
    $queue->insert([$rank, 0, $bundle, $bundle->length]) if $bundle;
  };

  print_log('p_sort', 'Get list ranking') if DEBUG;

  # Get the rank reference
  $self->{stack} = [$queue->reverse_array];
};



# Move to the next item in the sorted list
sub next {
  my $self = shift;

  if ($self->{top_k} && $self->{pos}++ >= $self->{top_k}) {

    if (DEBUG) {
      print_log(
        'p_sort',
        'top_k ' . $self->{top_k} . ' is reached at position ' . $self->{pos}
      );
    };

    $self->{current} = undef;
    return;
  };


  # Initialize query - this will do a full run on the first field level!
  $self->_init;

  # There are sorted results in the result list
  if (scalar @{$self->{sorted}}) {

    # Make this current
    $self->{current} = shift @{$self->{sorted}};

    if (DEBUG) {
      print_log(
        'p_sort',
        'There is already a match in [sorted]: ' . $self->{current}->to_string,
      );
    };

    return 1;
  }

  # Nothing presorted
  elsif (DEBUG) {
    print_log('p_sort', 'There is no match in [sorted]');
  };

  # Get the list values
  my $stack = $self->{stack};

  # This will get the level from the stack
  my $level = $#{$stack};

  print_log('p_sort', "Check stack on current level $level") if DEBUG;

  # If the current list is empty, remove from stack
  while (scalar @$stack && (
    !scalar(@{$stack->[$level]}) ||
      !scalar(@{$stack->[$level]->[0]})
    )) {

    print_log('p_sort', "Stack is empty at least on level $level") if DEBUG;

    pop @$stack;
    $level--;

    #if (DEBUG) {
    #  print_log('p_sort', "Stack is reduced to level $level with " . Dumper($stack));
    #};
  };

  # There is nothing to sort further
  unless (scalar @$stack) {

    print_log('p_sort', 'There is nothing to sort further') if DEBUG;

    $self->{current} = undef;
    return;
  };

  # while (my $same = $list->[0]->[SAME]) {
  #   $list = $self->heap_sort();
  # };

  # TODO:
  #   Depending on how many identical ranks exist,
  #   here the next strategy should be chosen.
  #   Either sort in place, or sort using heapsort again.

  # The first item in the current list has multiple identical ranks
  # As long as the first item in the list has duplicates,
  # order by the next level
  while ((my $same = ($stack->[$level]->[0]->[SAME] // 1)) > 1) {

    if (DEBUG) {
      print_log(
        'p_sort',
        "Found $same matches at first node",
        "  on level $level in " . _string_array($stack->[$level])
      );
    };

    # Get the identical elements from the list
    my @presort = splice(@{$stack->[$level]}, 0, $same - 1);

    print_log('p_sort', 'Presort array is ' . _string_array(\@presort)) if DEBUG;

    # TODO:
    #   Push presort on the stack!

    # This is the new top_k!
    # TODO:
    #   Check if this is really correct!
    my $top_k = $self->{top_k} - ($self->{pos} - 1);

    # Get next field to rank on level
    # level 0 is preinitialized, so it is one off
    #my ($field, $desc) = @{$self->{fields}->[$level + 1]};

    #if (DEBUG) {
    #  print_log('p_sort', qq!Next Rank on field "$field"!);
    #};

    #$level++;

    ## TODO:
    ##   If the same count is smaller than X (at least top_k - pos)
    ##   do quicksort or something similar
    ## if ($same < $top_k || $same < 128) {
    ## }
    ## else
    #$stack->[$level] = $self->heap_sort($top_k, \@presort, $field, $desc);
    ## };

    if (DEBUG) {
      print_log(
        'p_sort',
        "Sorted array",
        "  on new level $level is " . _string_array($stack->[$level])
      );
    };
  };

  # There are matches on the list without identical ranks

  if (DEBUG) {
    print_log('p_sort', "Stack with level $level is " . Dumper($stack));
  };

  # Get the top list entry
  my $top = shift @{$stack->[$level]};

  print_log('p_sort', 'Push value ' . $top->[VALUE]) if DEBUG;

  # Push matches to result list
  push @{$self->{sorted}}, $top->[VALUE]->unbundle;

  # Make the first match the current
  # TODO: Be aware! This is a BUNDLE!
  $self->{current} = shift @{$self->{sorted}};
  return 1;
};



# Return the current match
sub current {

  if (DEBUG) {
    print_log('p_sort', 'Current posting is ' . $_[0]->{current}->to_string);
  };

  $_[0]->{current};
};


# Get the current match object
sub current_match {
  my $self = shift;
  my $current = $self->current or return;
  my $match = Krawfish::Koral::Result::Match->new(
    doc_id  => $current->doc_id,
    start   => $current->start,
    end     => $current->end,
    payload => $current->payload,
  );

  if (DEBUG) {
    print_log('p_sort', 'Current match is ' . $match->to_string);
  };

  return $match;
};


# Return the number of duplicates of the current match
sub duplicate_rank {
  my $self = shift;

  if (DEBUG) {
    print_log('p_sort', 'Check for duplicates from index ' . $self->{pos});
  };

  return $self->{list}->[$self->{pos}]->[1] || 1;
};


sub to_string {
  my $self = shift;
  my $str = 'sort(';
  $str .= $self->{sort}->to_string;
  $str .= ',0-' . $self->{top_k} if $self->{top_k};
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






# Todo:
#   Accept an iterator, a ranking, and return an iterator
sub heap_sort {
  my ($self, $top_k, $sub_list, $field, $desc) = @_;

  warn 'DEPRECATED';

  if (DEBUG) {
    print_log('p_sort', 'Heapsort list of length ' . scalar(@$sub_list) .
                qq! by field "$field" for top_k = $top_k!);
  };

  my $index = $self->{index};
  my $ranking = $index->fields->ranked_by($field);

  # Get maximum rank if descending order
  my $max = $ranking->max if $desc;

  # Get maximum rank
  my $max_rank = $index->max_rank;
  my $max_rank_ref = \$max_rank;

  # Create new priority queue
  my $queue = Krawfish::Util::PriorityQueue::PerDoc->new(
    $top_k,
    $max_rank_ref
  );

  my $rank;

  # Iterate over list
  foreach (@$sub_list) {
    my $bundle = $_->[VALUE];

    # Get stored rank
    $rank = $ranking->get($bundle->doc_id);

    # Revert if maximum rank is set
    $rank = $max - $rank if $max;

    # Insert into queue
    $queue->insert([$rank, 0, $bundle, $bundle->length]);
  };

  # Return reverse list
  return $queue->reverse_array;
};




1;

__END__

