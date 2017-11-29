package Krawfish::Index::Fields::Rank;
use Krawfish::Util::String qw/squote/;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 1;

# TODO:
#   Merge plain and sorted lists, so there is only
#   one list with values and doc ids, that
#   accepts new entries, can be merged with new entries,
#   can create ranks in both orders and
#   can return values per rank.

# TODO:
#   It may be useful for criterion generation
#   to have witnesses for ranks, e.g. the ranking list
#   points to the list of sorted values.
#   Unfortunately this would mean that there can't be front-encoding.

# TODO:
#   On commit keep a note if a field is
#   listed twice for at least one document
#   If not, the descending ranks can be calculated
#   using the max_rank rather than storing
#   the inverse data redundantly

# TODO:
#   For encoding dense but not diverse field ranks use something like that:
#   http://pempek.net/articles/2013/08/03/bit-packing-with-packedarray/
#   https://github.com/gpakosz/PackedArray
#   That's why max_rank is important, because it indicates
#   how many bits per doc are necessary to encode
#   the rank ceil(log(N)/log(2))!
#   https://arxiv.org/pdf/1401.6399.pdf
#   https://github.com/zhenjl/encoding

# TODO:
#   In case, a field is only set for a couple of documents, a different
#   strategy may be valid.

# TODO:
#   Think about a different design, where the field lists are stored on the
#   node level:
#     [collation]([field-term-with-front-coding][term_id])
#   Now, the new terms will be merged in the list and the new segment will incorporate
#   the new ranking.
#   When a new term is added, it is added as
#     ([term][term_id][doc_id])*
#   ...

sub new {
  my $class = shift;
  bless {

    # This is stored
    collation => shift,
    sort      => [],
    asc       => [],
    desc      => [],
    max_rank  => 0,

    buffer    => [],
    buffered  => 0,
    sorted    => 0,
    ranked    => 0
  }, $class;
};


# Add a new field value
sub add {
  my ($self, $value, $doc_id) = @_;

  my $coll = $self->{collation};

  if (DEBUG) {
    print_log('f_rank', 'Add ' . squote($value) . ' for doc_id ' . $doc_id);
  };

  # Get buffer
  my $buffer = $self->{buffer};

  # Collation is numerical
  if ($coll eq 'NUM') {
    push @{$self->{buffer}}, [$value, $doc_id];
  }

  # Collation is numerical with range
  elsif ($coll eq 'NUMRANGE') {

    # TODO:
    #   Not yet implemented
    my ($min, $max) = $coll->min_max($value);
    push @{$self->{buffer}}, [$min, $doc_id];
    push @{$self->{buffer}}, [$max, $doc_id];
  }

  # Collation is date with range
  elsif ($coll eq 'DATERANGE') {

    # TODO:
    #   Not yet implementated
    my ($min, $max) = $coll->min_max($value);
    push @{$self->{buffer}}, [$coll->date_num($min), $doc_id];
    push @{$self->{buffer}}, [$coll->date_num($max), $doc_id];
  }

  # Collation is a date
  elsif ($coll eq 'DATE') {

    # TODO:
    #   Not yet implementated
    push @{$self->{buffer}}, [$coll->date_num($value), $doc_id];

  }

  # Use collation
  else {

    # Add sortkey to buffer
    push @{$self->{buffer}}, [$coll->sort_key($value), $doc_id];
  };


  return $self->{buffered} = 1;

  return;
};


# Get max_rank
sub max_rank {
  $_[0]->{max_rank};
};


# Commit all changes
sub commit {
  my $self = shift;

  # TODO:
  #   It's probably better to sort by collocation and store
  #   the comparation keys without front-coding, making it
  #   skippable as well, so the structure is
  #   [collocation]([skip-data]([rank][length][comparation-key|value][doc_id]*)*)*
  #   As not every rank will have a skip-embedding, it's possible
  #   to use front-encoding / delta-encoding while in a skip-chunk.

  # TODO:
  #   This requires a change for ranges!
  #   In that case, the ascending order will use the minimum value
  #   and the descending order will use the maximum value
  #   (per doc in case of multiple ranges)

  # Return if everything commited
  return unless $self->{buffered};

  # 1. sort the plain list following
  #    the collation
  #    Creates the structure
  #    [collocation]([field-term-with-front-coding|value-as-delta][doc_id]*)*

  my $buffer = $self->{buffer};

  if (DEBUG) {
    print_log('f_rank', 'Sort buffer');
  };

  my @sorted_buffer = $self->{collation} eq 'NUM' ?
    _numsort_fields($self->{buffer}) :
    _keysort_fields($self->{buffer});

  my $last_value;

  # TODO:
  #   Deal with already sorted list!
  my $sort = $self->{sort};
  my $coll = $self->{collation};
  my $pos = 0;

  # Iterate over sorted buffer
  # TODO:
  #   This should automatically merge with
  #   an existing list
  my $max_rank = $self->{max_rank};

  if (DEBUG) {
    print_log('f_rank', 'Maximum rank so far is ' . $max_rank);
  };

  foreach my $next (@sorted_buffer) {

    if (DEBUG) {
      print_log('f_rank', 'Check next item from buffer ' . $next->[0]);
    };

    my $current_sort = $sort->[$pos];

    # Move to the first item in the sorted
    # list that is > than current
    while (
      $current_sort && (
      $coll eq 'NUM' ?
        $current_sort->[0] < $next->[0] :
        $current_sort->[0] lt $next->[0])
    ) {

      if (DEBUG) {
        print_log(
          'f_rank',
          "At $pos - Move on till next is larger: " .
          $current_sort->[0] . ' < ' . $next->[0]
        );
      };

      # Get to next sort entry
      $current_sort = $sort->[++$pos];
    };

    # The last value is given and it's equal to the next value
    if (defined $current_sort && (
      $coll eq 'NUM' ?
        $next->[0] == $current_sort->[0] :
        $next->[0] eq $current_sort->[0])
      ) {

      if (DEBUG) {
        print_log(
          'f_rank',
          "At $pos - Sort and next are identical, add doc: " .
            $next->[0] . ' == ' . $next->[0]
        );
      };

      # Add doc id to the current sort item
      push @{$current_sort}, $next->[1];
    }

    # The new entry is in the middle of the sorted list
    else {

      # Add value => doc_id field
      if ($pos > $#$sort) {

        # Add it to the end
        push(@$sort, [$next->[0], $next->[1]]);
      }

      # Add it in the middle
      else {
        splice(@$sort, $pos, 0, [$next->[0], $next->[1]]);
      };
      $max_rank++;
    };

    if (DEBUG) {
      print_log('f_rank',"At $pos - New sort: " . $self->to_string($pos));
    };
  };


  $self->{sorted} = 1;
  $self->{buffer} = [];
  $self->{buffered} = 0;
  $self->{ranked} = 0;
  $self->{max_rank} = $max_rank;

  if (DEBUG) {
    print_log('f_rank', 'List is is ' . $self->to_string);
  };

  return 1;
};


# Sort data
sub vector {
  my $self = shift;
  return $self->{sort} if $self->{sorted};
  return [];
};


# Create ranks
sub _create_ranks {
  my $self = shift;

  # Already ranked
  return if $self->{ranked};

  # Create the ascending rank
  my (@asc, @desc) = ();

  my $pos_rank = 1;
  my $neg_rank = $self->max_rank;

  if (DEBUG) {
    print_log('f_rank', 'Rank the list');
  };

  foreach my $entry (@{$self->vector}) {

    # Get all documents associated with the rank
    foreach (@{$entry}[1..$#$entry]) {

      # Only set the value,
      # if not ranked yet
      $asc[$_] //= $pos_rank;
      $desc[$_] = $neg_rank;
    };

    $pos_rank++;
    $neg_rank--;
  };

  if (DEBUG) {
    print_log(
      'f_rank',
      'Ascending ranks per doc are ' .
        join('', map { $_ ? "[${_}]" : '[]' } @asc)
      );
  };

  $self->{asc} = \@asc;
  $self->{desc} = \@desc;

  $self->{ranked} = 1;
  return;
};


# Get the key for a certain asc rank
sub asc_key_for {
  my ($self, $rank) = @_;

  # TODO:
  #   This should only load the sort if necessary

  my $entry = $self->{sort}->[$rank-1];

  # return value
  return $entry->[0];
};


# Get the key for a certain desc rank
sub desc_key_for {
  my ($self, $rank) = @_;

  # TODO:
  #   This should only load the sort if necessary

  my $entry = $self->{sort}->[($self->max_rank - $rank)];

  # return value
  return $entry->[0];
};


# Get ascending ranks
sub asc_rank_for {
  my ($self, $doc_id) = @_;

  # TODO:
  #   This should only load the asc rank on request
  $self->_create_ranks;
  $self->{asc}->[$doc_id] // 0;
};


# Get descending ranks
sub desc_rank_for {
  my ($self, $doc_id) = @_;

  # TODO:
  #   This should only load the desc rank on request
  $self->_create_ranks;
  $self->{desc}->[$doc_id] // 0;
};



# Sort by comparation key
sub _keysort_fields {
  my $plain = shift;

  return sort { $a->[0] cmp $b->[0] } @$plain;
};


# Numerical sorting
sub _numsort_fields {
  my $plain = shift;

  # Or sort numerically
  return sort { $a->[0] <=> $b->[0] } @$plain;
};


# Stringification
sub to_string {
  my ($self, $pos) = @_;

  my $str = '';
  my $coll = $self->{collation} eq 'NUM' ? 1 : 0;

  # Sorted list
  if (@{$self->{sort}}) {
    $str .= '<';

    my $i = 0;
    foreach (@{$self->{sort}}) {
      $str .= '(' if defined $pos && $i == $pos;
      $str .= ($coll ? $_->[0] : '?') . ':' . join(',', @{$_}[1..$#{$_}]);
      $str .= ')' if defined $pos && $i == $pos;
      $str .= ';';
      $i++;
    };
    chop($str);
    $str .= '>';
  };

  # Buffered list
  if ($self->{buffered}) {
    $str .=
      '{' . join(';', map { ($coll ? $_->[0] : '?') . ':' . $_->[1] } (@{$self->{buffer}})) . '}';
  };

  return $str;
};


sub to_doc_string {
  my $self = shift;

  my $str = '';

  # Sorted list
  if ($self->{sorted}) {
    $str .= join('', map { '[' . join(',', @{$_}[1..$#{$_}]) . ']' }
                   (@{$self->{sort}}));
  };

  return $str;
};


# Return ascending ranks
sub to_asc_string {
  my $self = shift;
  $self->_create_ranks;
  return join('', map { $_ ? "[${_}]" : '[]' } @{$self->{asc}})
};


# return descending string
sub to_desc_string {
  my $self = shift;
  $self->_create_ranks;
  return join('', map { $_ ? "[${_}]" : '[]' } @{$self->{desc}})
};


1;

