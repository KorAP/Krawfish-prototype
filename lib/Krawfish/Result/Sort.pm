package Krawfish::Result::Sort;
# use Krawfish::Result::Sort::InitRank;
# use Krawfish::Result::Sort::Rank;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

# See Krawfish::Util::Buckets

# TODO:
#  Sort is currently limited to sorting for searching.
#  It should also be able to sort groups or sort texts/documents/corpora
#
# TODO:
#   This may even help filtering: Whenever a document is matched with a rank
#   that can be ignored (i.e. below the buckets of interest), skip the whole document.
#   This could in fact be done manipulating the external virtual corpus filter!
#
# TODO:
#   Whenever top X is requested, and there are matches > X with a max_rank Y,
#   ignore all matches > Y. This also means, these matches do not need to be
#   fine-sorted using secondary fields.
#
# TODO:
#   This should - as a by product - count frequencies
#
# TODO:
#   This should also release top items as early as possible
#
# TODO:
#   This should bin-sort everything in case it's called using a streaming API
#
#
# TODO:
#   Start with init at the beginning of next
#

# TODO:
# - Sorting should not only support top_k but also limit!
#   By that, all top_k matches will be sorted in the first pass,
#   but in the second pass, matches in the offset may not
#   necessarily be perfectly sorted by further passes.

sub new {
  my $class = shift;
  my $self = bless {
    query => shift,
    index => shift,
    fields => shift,
    freq => 0,
    pos => -1, # Temporary
    # top_k => shift // 0 # TODO!
  }, $class;

  my $query = $self->{query};
  my $index = $self->{index};

  # Fields
  my $field_obj = $index->fields;

  my @record_order; # Currently contains clones!

  # TODO:
  my @equally_ranked;

  # First sort criteria
  my $i = 0;
  my $sort_by = $self->{fields}->[$i++];
  # TODO: Use '::FirstPass'!
  my $rank = $field_obj->ranked_by($sort_by);

  # TODO:
  #   This may need to create a cached result buffer
  #   and a linked list with offset information augmented.
  #   That way it's trivial to resort the document later on!

  # TODO: Probably use next_doc
  #
  # TODO: This requires a cached buffer
  while ($query->next) {

    print_log('c_sort', 'Get next posting from query ' . $query->to_string) if DEBUG;

    # Add cloned
    my $element = $query->current->clone;
    push @record_order, $element;
    $self->{freq}++;

    print_log('c_sort', 'Clone ' . $element->to_string) if DEBUG;

    # TODO:
    # my $offset = $current->offset; # record-offset in cached buffer!

    # Get the rank of the doc in O(1)
    # If rank is not set, set max_rank + 1

    # TODO: This should be added sorted
    # TODO: Use something like tree sort
    # TODO: Add identical field-docs at position 2!
    # my $pos = 4; # is a pointer to the first identical element in the list
    # push @record_order, [$offset, $doc_rank];

    # There are identical fields ...
    # if ($record_order[$pos - 1] eq $record_order[$pos]) {
    #   # TODO: Only mark the first identical occurrence
    #   push @equally_ranked, $pos - 1;
    # };
  };

  print_log('c_sort', 'Check ranking') if DEBUG;

  my $max = $rank->max;
  $self->{ordered} = [sort {
    my $rank_a = $rank->get($a->doc_id) || ($max + 1);
    my $rank_b = $rank->get($b->doc_id) || ($max + 1);
    return $rank_a <=> $rank_b;
  } @record_order];

  print_log(
    'c_sort',
    "Ordered by rank '$sort_by' is " . join(',', @{$self->{ordered}})
  ) if DEBUG;

  return $self;


  # TODO:

  # nth pass fine-sort - Iterate over remaining fields
  # If there are remaining unsorted fields at the end, sort by identifier
  for (; $i <= @{$self->{sort_by}}; $i++) {
    $sort_by = $self->{sort_by}->[$i];

    # Get the rank of the field
    # This should probably be an object instead of an array
    $rank = $field_obj->ranked_by($sort_by);

    # At the beginning, iterate over all docs

    # The list is already sorted by former fields - refine!
    if (@equally_ranked) {
      ...
    }

    # The list is already finally ranked
    else {
      last;
    };
  };

  # record_order now contains a linked list of offsets
  # to the cached buffer
  #
  # The next etc. should be nextable!

  return $self;
};


# Iterated through the ordered linked list
sub next {
  my $self = shift;
  if ($self->{pos}++ < ($self->freq - 1)) {
    return 1;
  };
  return;
};


# Get frequency
sub freq {
  $_[0]->{freq};
};


sub current {
  my $self = shift;
  return $self->{ordered}->[$self->{pos}] // undef;
};


sub to_string {
  my $self = shift;
  my $str = 'collectSorted(';
  $str .= '[' . join(',', map { _squote($_) } @{$self->{fields}}) . ']:';
  $str .= $self->{query}->to_string;
  return $str . ')';
};


# From Mojo::Util
sub _squote {
  my $str = shift;
  $str =~ s/(['\\])/\\$1/g;
  return qq{'$str'};
};


1;


__END__



sub new {
  my $class = shift;
  my ($query, $index, $fields, $top_k, $param) = @_;

  my $self = bless {
    query  => $query,
    index  => $index,
    fields => $fields,
    freq   => 0,
    pos    => -1, # Temporary
    top_k  => $top_k,
    offset => $offset
  }, $class;

  # fields have the structure [['author'],['title', 1]]
  # with the first value being the field and the second being a
  # boolean value indicating descending order.


  # Get field accessor
  my $field_obj = $index->fields;

  # Get the first order for the initial pass
  my $i = 0;
  my $sort_by = $self->{fields}->[$i++];
  my $rank = $field_obj->ranked_by($sort_by->[0]);

  # TODO:
  #   This may need to create a cached result buffer
  #   and a linked list with offset information augmented.
  #   That way it's trivial to resort the document later on!

  # TODO: Probably use next_doc
  #

  # This may be different, in case top_k is not set
  $self->_first_pass;
};


sub _first_pass {
  my $self = shift;

  my $priority = Krawfish::Result::Sort::InitRank->new(
    query => $query
  )

  # Sort first pass
  while ($query->next) {

    print_log('c_sort', 'Get next posting from query ' . $query->to_string) if DEBUG;

    # Add cloned
    my $element = $query->current->clone;

      # It's necessary to sort in descending order
  if ($sort_by->[1]) {
    $rank->
  };


    push @record_order, $element;

    print_log('c_sort', 'Clone ' . $element->to_string) if DEBUG;

    # TODO:
    # my $offset = $current->offset; # record-offset in cached buffer!

    # Get the rank of the doc in O(1)
    # If rank is not set, set max_rank + 1

    # TODO: This should be added sorted
    # TODO: Use something like tree sort
    # TODO: Add identical field-docs at position 2!
    # my $pos = 4; # is a pointer to the first identical element in the list
    # push @record_order, [$offset, $doc_rank];

    # There are identical fields ...
    # if ($record_order[$pos - 1] eq $record_order[$pos]) {
    #   # TODO: Only mark the first identical occurrence
    #   push @equally_ranked, $pos - 1;
    # };
  };

  print_log('c_sort', 'Check ranking') if DEBUG;

  my $max = $rank->max;
  $self->{ordered} = [sort {
    my $rank_a = $rank->get($a->doc_id) || ($max + 1);
    my $rank_b = $rank->get($b->doc_id) || ($max + 1);
    return $rank_a <=> $rank_b;
  } @record_order];

  print_log(
    'c_sort',
    "Ordered by rank '$sort_by' is " . join(',', @{$self->{ordered}})
  ) if DEBUG;

  return $self;


  # TODO:

  # nth pass fine-sort - Iterate over remaining fields
  # If there are remaining unsorted fields at the end, sort by identifier
  for (; $i <= @{$self->{sort_by}}; $i++) {
    $sort_by = $self->{sort_by}->[$i];

    # Get the rank of the field
    # This should probably be an object instead of an array
    $rank = $field_obj->ranked_by($sort_by);

    # At the beginning, iterate over all docs

    # The list is already sorted by former fields - refine!
    if (@equally_ranked) {
      ...
    }

    # The list is already finally ranked
    else {
      last;
    };
  };

  # record_order now contains a linked list of offsets
  # to the cached buffer
  #
  # The next etc. should be nextable!

  return $self;
}

