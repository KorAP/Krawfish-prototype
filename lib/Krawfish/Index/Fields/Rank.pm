package Krawfish::Index::Fields::Rank;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 1;

# TODO:
#   Split ranks in asc_rank and desc_rank,
#   as only one rank needs to be lifted
#   on a sort

# TODO:
#   On commit keep a note if a field is
#   listed twice for at least one document
#   If not, the descending ranks can be calculated
#   using the max_rank rather than storing
#   the data redundantly

sub new {
  my $class = shift;
  bless {
    collation => shift,
    asc       => [],
    desc      => [],
    sorted    => [],
    plain     => [],
    max_rank  => undef
  }, $class;
};


# Add an entry to the plain list
sub add {
  my $self = shift;
  my ($value, $doc_id) = @_;

  if (DEBUG) {
    print_log('f_rank', qq!Add value "$value" associated to ! . $doc_id)
  };

  push @{$self->{plain}}, [$value, $doc_id];
};



# Prepare the plain list for merging
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

  # Sort the list
  my @presort = sort { $a->[0] cmp $b->[0] } @{$self->{plain}};

  # Remove duplicates
  my @sort;
  my $last_value;
  foreach my $next (@presort) {
    if ($last_value && $next->[0] eq $last_value) {
      push @{$sort[-1]}, $next->[1]
    }
    else {
      push @sort, [$next->[1]];
      $last_value = $next->[1];
    };
  };

  # This list keeps existing, even
  # when the segment becomes static -
  # to make merging possible without the
  # need to reconsult the dictionary
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

  $self->{asc} = \@asc;

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

  $self->{desc} = \@desc;
  $self->{plain} = [];

  return $self;

  # 4. Compress the sorted list
  #    Because the list is only needed
  #    for merging, it can be
  #    stored compressed
};


# TODO:
#   Rename to asc_rank and desc_rank
sub asc_rank {
  my ($self, $doc_id) = @_;
  $self->{asc}->[$doc_id];
};

sub desc_rank {
  my ($self, $doc_id) = @_;
  $self->{desc}->[$doc_id];
};

sub to_string {
  my $self = shift;
  if ($self->{sorted}) {
    return join '', map { '[' . join(',', @{$_}) . ']' } @{$self->{sorted}};
  }
  else {
    return '?';
  };
};


1;
