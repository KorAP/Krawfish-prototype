package Krawfish::Index::Dictionary;
use strict;
use warnings;
use Krawfish::Log;
use Krawfish::Index::PostingsList;

# TODO:
#   In production the dictionary will be implemented using
#   two data structures:
#   - A dynamic TST (either balancing or self-optimizing)
#   - A static complete TST (compact, fast (de)serializale,
#     cache-optimized, small)
#   - The dynamic tree is used to add new terms.
#     It potentially can also delete terms or mark terms (nodes)
#     as being deleted.
#   - The dynamic and the static tree are searchable
#     (though it's acceptable if the dynamic TST is slower)
#   - The dynamic and the static trees support reverse lookup
#     (that is, retrieving the term by a term id)
#   - The static tree does not support adding or
#     deleting of nodes.
#   - The dynamic tree can be serialized to a static tree
#   - The dynamic tree can merge (while being serialized)
#     with a static tree.
#   - Whenever the dynamic tree contains a reasonable
#     amount of terms, it can merge with a second static
#     dictionary in memory, write to disc,
#     and exchange the old dictionary with the new one.

# TODO: Use Storable
# TODO: Support case insensitivity
# TODO: Create forward index with term-ids
# TODO: Support aliases (e.g. a surface term may have the
#   same postings list throughout foundries)
#
# TODO:
#   For fields it's necessary to have methods to add
#   a term and retrieve entries before and after, in case
#   a term is not yet added. This gives the possibility
#   to retrieve ranks for this field value and rerank the
#   field rank in place (meaning the new value has the
#   rank of the next value in the dictionary and in the
#   FieldsRank all documents with a rank > the new
#   rank value needs to be incremented.
#   However, keep in mind: That only works for fields
#   with the same collation mechanism as the dictionary.
#
# TODO:
#   For surface terms in subtoken-boundaries (ONLY),
#   store a prefix-rank and a suffix rank,
#   to make it easy to sort surface terms by their term_id on the fly.
#   A data structure that supports relational ordering (let's say
#   the previous term has the rank 3 and the folowing has the term
#   4 and you want to add it as 3.5) would be nice
#
# TODO:
#   In Lucy the dictionary is stored in a list
#   using incremental encoding / front coding.
#
# PREFIXES:
#   terms: *
#   subterms: ~
#   fields: + (need to be )

#
# TERMS: The dictionary will have one value lists with data,
#        accessible by their term_id position in the list:
#
#  ([leaf-backref][freq][postinglistpos])*
#
#  However - it may be useful to have the postinglistpos
#  separated per segment, so it's
#  seg1:[postinglistpos1][postinglistpos2][0][postinglistpos4]
#  seg1:[postinglistpos1][postinglistpos2][postinglistpos3][0]
#  ...
#
# SUBTERMS: The dictionary will have one list with data,
#           accessible by their sub_term_id position in the list:
#  ([leaf-backref][prefix-rank][suffix-rank])*
#
use constant DEBUG => 0;

sub new {
  my $class = shift;
  my $file = shift;
  bless {
    file => $file,
    hash => {},   # Contain the dictionary

    # This will probably be one array in the future
    prefix_rank => [],
    suffix_rank => [],
    ranked => 0,

    # TEMP helper arrays for (sub)term_id -> (sub)term mapping
    term_array => [],
    subterm_array => [],

    # Bookkeeping for (sub)term_ids
    last_term_id => 1,
    last_subterm_id => 1,

    # TODO: Collation needs to be defined!
    collation => undef
  }, $class;
};


# Add should return term-id (or term-string)
sub add_term {
  my $self = shift;
  my $term = shift;

  print_log('dict', "Added term $term") if DEBUG;

  my $hash = $self->{hash};

  # Term not in dictionary yet
  unless (exists $hash->{$term}) {

    # Increment term_id
    # TODO: This may infact fail, as term_ids are limited in size.
    #   For hapax legomena, a special null marker will be returned
    my $term_id = $self->{last_term_id}++;

    # Create new listobject
    $hash->{$term} = Krawfish::Index::PostingsList->new(
      $self->{file}, $term, $term_id
    );

    # Store term for term_id mapping
    $self->{term_array}->[$term_id] = $term;
  };
  return $hash->{$term};
};


# Add subterm to dictionary
# The subterm does not need to be searched, so the mechanism is only used
# to guarantee that subterms are unique.
# There may be a better data structure for this, though.
sub add_subterm {
  my ($self, $subterm) = @_;

  print_log('dict', "Added subterm $subterm") if DEBUG;

  my $hash = $self->{hash};
  my $subterm_id;

  # Subterm not in dictionary yet
  unless ($subterm_id = $hash->{'~' . $subterm}) {

    # Increment sub_term_id
    # TODO: This may infact fail, as term_ids are limited in size.
    #   For hapax legomena, a special null marker will be returned
    $subterm_id = $self->{last_subterm_id}++;

    $self->{ranked} = 0;

    # TODO: Based on the subterms, the rankings will be processed

    # Store subterm for term_id mapping
    $self->{subterm_array}->[$subterm_id] = $subterm;

    # Add subterm to set
    $hash->{'~' . $subterm} = $subterm_id;
  };

  return $subterm_id;
};


# Return pointer in list
sub pointer {
  my ($self, $term) = @_;
  print_log('dict', 'Try to retrieve pointer ' . $term) if DEBUG;
  my $list = $self->{hash}->{$term} or return;
  return $list->pointer;
};


# Return the term from a term_id
# This needs to be fast (can't be done like this)
sub term_by_term_id {
  my ($self, $term_id) = @_;
  print_log('dict', 'Try to retrieve term id ' . $term_id) if DEBUG;
  return $self->{term_array}->[$term_id];
};

sub subterm_by_subterm_id {
  my ($self, $subterm_id) = @_;
  print_log('dict', 'Try to retrieve subterm id ' . $subterm_id) if DEBUG;
  return $self->{subterm_array}->[$subterm_id];

};

# Returns a rank value by a certain subterm_id
sub prefix_rank_by_subterm_id {
  my ($self, $subterm_id) = @_;
  $self->process_subterm_ranks;
  $self->{prefix_rank}->[$subterm_id];
};

sub suffix_rank_by_subterm_id {
  my ($self, $subterm_id) = @_;
  $self->process_subterm_ranks;
  $self->{suffix_rank}->[$subterm_id];
};

# if a term has no term_id it also has no rank,
# so this will return the rank of the preceeding term in the dictionary.
# TODO: When having matches stored in buckets, there is always a bool accompanied
# to the rank, saying the rank is exact or not.
# sub rank_by_subterm;
# sub rev_rank_by_subterm;

# Returns the term id by a term
# Currently this is a bit complicated to the round trip
# Using the postings list - should be stored directly in the dictionary!
sub term_id_by_term {
  my ($self, $term) = @_;
  print_log('dict', 'Try to retrieve term ' . $term) if DEBUG;
  my $list = $self->{hash}->{$term};
  return $list->term_id if $list;
  return;
};


# Return terms of the term dictionary
# TODO: This should return an iterator
sub terms {
  my ($self, $re) = @_;

  if ($re) {
    return sort grep { $_ =~ $re } keys %{$self->{hash}};
  };

  return keys %{$self->{hash}};
};

sub process_subterm_ranks {
  return if $_[0]->{ranked};
  my $self = shift;
  # TODO:
  # For prefix rank:
  # Iterate over prefix tree in in-node order
  # and generate a rank for the subtree of the subterm.
  # ...
  # For suffix rank:
  # Iterate over prefix tree
  # and sort by suffix using
  # bucketsort or mergesort to
  # create a sorted rank

  # Iterate over all subterms alphabetically
  my $i = 0;
  my @subt = grep { index($_, '~') == 0 } keys %{$self->{hash}};
  foreach my $subterm (sort @subt) {

    # Set subterm_id to prefix rank
    $self->{prefix_rank}->[$i++] = $self->{hash}->{$subterm};
  };

  # Iterate over all subterms based on their suffixes
  $i = 0;
  foreach my $subterm (sort { reverse($a) cmp reverse($b) } @subt) {

    # Set subterm_id to prefix rank
    $self->{suffix_rank}->[$i++] = $self->{hash}->{$subterm};
  };

  $_[0]->{ranked} = 1;
};



1;
