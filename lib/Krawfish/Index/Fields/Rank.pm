package Krawfish::Index::Fields::Rank;
use Krawfish::Index::Fields::Direction;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

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

# Constructor
sub new {
  my $class = shift;

  if (DEBUG) {
    print_log('f_rank', 'Initiate rank object');
  };

  bless {
    collation => shift,

    # If calc_desc is activated,
    # the rank is ascending, but desc can be calculated
    # based on max_rank.
    # This is only possible for single-valued fields
    calc_desc => shift,
    asc       => Krawfish::Index::Fields::Direction->new,
    desc      => Krawfish::Index::Fields::Direction->new,
    sorted    => [], # Better: Krawfish::Index::Fields::Sorted
    plain     => [],
    max_rank  => undef
  }, $class;
};


# Add an entry to the plain list
sub add {
  my $self = shift;
  my ($value, $doc_id) = @_;

  if (DEBUG) {
    print_log('f_rank', qq!Add value "$value" associated to $doc_id!);
  };

  # TODO:
  #   Request the type of a collation, to support
  #   numerical, numerical range, date, date range,
  #   and string collations.

  # Collation is numerical
  if ($self->{collation} eq 'NUM') {
    push @{$self->{plain}}, [$value, $doc_id];
  }

  # Collation is numerical with range
  elsif ($self->{collation} eq 'NUMRANGE' || $self->{collation} eq 'DATERANGE') {

    # TODO:
    #   Not yet implemented
    my ($min, $max) = $self->{collation}->min_max($value);
    push @{$self->{plain}}, [$min, $max, $doc_id];
  }

  # Collation is a date
  elsif ($self->{collation} eq 'DATE') {

    # TODO:
    #   Not yet implementated
    my $date = $self->{collation}->date_num($value);
    push @{$self->{plain}}, [$date, $doc_id];

  }

  # Use collation
  else {
    push @{$self->{plain}}, [$self->{collation}->sort_key($value), $doc_id];
  };

  if (DEBUG) {
    print_log(
      'f_rank',
      qq!Plain ranks are [VALUE,DOC_ID] ! .
        join('', map { '[' . join(',',@$_) . ']' } @{$self->{plain}})
      );
  };

  $self->{max_rank} = undef;
  $self->{sorted}   = [];
};


# Get the maximum rank
sub max_rank {
  $_[0]->{max_rank};
};


# Prepare the plain list for merging,
# maybe for enrichment with sort criteria,
# or - for the moment - to become
# rankable
sub commit {
  my $self = shift;

  # Return if everything commited
  return if $self->{max_rank};

  # 1. sort the plain list following
  #    the collation
  #    Creates the structure
  #    [collocation]([field-term-with-front-coding|value-as-delta][doc_id]*)*

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

  # Sort the list
  my @presort = $self->{collation} eq 'NUM' ?
    _numsort_fields($self->{plain}) :
    _alphasort_fields($self->{plain});

  if (DEBUG) {
    print_log(
      'f_rank',
      'Presorted list [VALUE,DOC] is ' .
        join('', map { '[' . join(',',@$_) . ']' } @presort)
      );
  };

  # This list keeps existing, even
  # when the segment becomes static -
  # to make merging possible without the
  # need to reconsult the dictionary

  # Remove duplicates
  my @sort;
  my $last_value;

  # Iterate over presort list
  foreach my $next (@presort) {

    # The last value is given and it's equal to the next value
    if (defined $last_value && ($next->[0] eq $last_value)) {

      # Add to the last added list
      push @{$sort[-1]}, $next->[1]
    }
    else {

      # Create new item
      push @sort, [$next->[1]];
      $last_value = $next->[0];
    };
  };

  if (DEBUG) {
    print_log(
      'f_rank',
      'Sorted list on ranks [DOC*] is ' .
        join('', map { '[' . join(',',@$_) . ']' } @sort)
      );
  };


  $self->{sorted} = \@sort;

  # Create the ascending rank
  my (@asc, @desc) = ();

  my $rank = 1;
  foreach my $doc_ids (@sort) {

    # Get all documents associated with the rank
    foreach (@$doc_ids) {

      # Only set the value,
      # if not ranked yet
      $asc[$_] //= $rank;
    };

    $rank++;
  };

  if (DEBUG) {
    print_log(
      'f_rank',
      'Ascending ranks per doc are ' .
        join('', map { "[${_}]" } @asc)
      );
  };

  $self->{asc}->load(\@asc);

  # Max rank is relevant for efficient encoding
  $self->{max_rank} = --$rank;

  # Iterate again for suffixes
  foreach my $doc_ids (@sort) {

    # Get all documents associated with the rank
    foreach (@$doc_ids) {

      # Take the last value
      $desc[$_] = $rank;
    };

    $rank--;
  };

  $self->{desc}->load(\@desc);

  return $self;

  # 4. Compress the sorted list
  #    Because the list is only needed
  #    for merging, it can be
  #    stored compressed
};


# Returns the sorted object
sub sorted {
  ...
};


# Get ascending ranking
sub ascending {
  $_[0]->{asc};
};


# Get descending ranking
sub descending {
  $_[0]->{desc};
}


# Stringification
sub to_string {
  my $self = shift;
  if ($self->{sorted}) {
    return join '', map { '[' . join(',', @{$_}) . ']' } @{$self->{sorted}};
  }
  else {
    return '?';
  };
};


# This should depend on collation
sub _alphasort_fields {
  my $plain = shift;

  return sort { $a->[0] cmp $b->[0] } @$plain;
};


# Numerical sorting
sub _numsort_fields {
  my $plain = shift;

  # Or sort numerically
  return sort { $a->[0] <=> $b->[0] } @$plain;
};


1;
