package Krawfish::Index::Dictionary;
use strict;
use warnings;
use Krawfish::Log;

# This class is the basic dictionary class. It provides a
# homogeneous interface to K::I::Dictionary::Dynamic and
# K::I::Dictionary::Static (versioned).
#
#   Dynamic:
#   - A dynamic TST (either balancing or self-optimizing)
#   Static:
#   - A static TST (compact, fast (de)serializale,
#     cache-optimized, small)
#
# Terms have different prefixes:
#
#   terms:       *
#   (casefolded) '
#   subterms:    ~
#   foundry:     ^
#   layer:       °
#   annotations
#     token      #   (not yet supported)
#     span       <>
#     relations  <, >
#     attributes @
#   fields:      +
#   fieldkeys:   !
#
# add_term:
#   First the static dictionary will do a look-up if the term exists,
#   then the dynamic dictionary will do an insert_or_search, meaning
#   an existing term will return the term_id and a non-existing term
#   will be added, returning a term_id.
#
#   For casefolded search, it may be necessary to index the casefolded
#   string as well, with the same term_id (though, the reverse lookup)
#   is not possible. The same MAY be useful for diacriticless search.
#
#   When a new subterm is added, a binary search on the static
#   rank file is done to find the alphabetically preceeding term of
#   the new term. This rank is then added to the dynamic rank.
#   This is done for the prefix list as well as for the suffix list.
#   It's beneficial to collect a bunch of new terms before doing the
#   ranking, so the new terms are ordered alphabetically in advance
#   before finding the preceding terms in the subterm rank file.
#   In that way, each preceeding match using binary search will narrow
#   the following binary search by moving the starting index.
#
#   A data structure that supports relational ordering (let's say
#   the previous term has the rank 3 and the folowing has the term
#   4 and you want to add it as 3.5) would be nice, but I wasn't
#   able to find one that's precise in all circumstances.
#
# term_to_term_id:
#   First a look-up to the static dictionary is done.
#   In case of failure, a lookup to the dynamic dictionary is done.
#
# search:
#   Returns an array of valid term_ids.
#   Required searches are:
#     - casefolded
#     - without_diacritics
#     - regular expression
#     - approximate matching
#     - wildcards
#   Both dictionaries are searched (maybe in parallel).
#
# term_id_to_term:
#   In case the term_id is larger than the largest term_id of the
#   static dictionary, make a reverse lookup in the dynamic dictionary,
#   otherwise make a reverse lookup in the static dictionary.
#   This feature may be more complicated when term_ids can be reused
#   (see delete).
#
# delete:
#   Not necessary, but could be implemented in both dictionaries.
#   In the dynamic dictionary the branches are removed.
#   In the static dictionary the term (and potentially branches)
#   are marked as deleted.
#   When both dictionaries are merged, removed terms may be
#   ignored. Though - this feature has not really any benefits,
#   as old term_ids can't be reused.
#
# merge:
#   Merges the static dictionary with the dynamic dictionary and
#   creates a new static dictionary.
#   This will also merge the ranks.
#
# rank_subterm:
#   Returns the numerical rank of a subterm in alphabetic order.
#   The static dictionary will return a simple even numerical rank
#   (calculated on merge). The dynamic dictionary will
#   return a simple odd numerical rank. Because odd ranks are not
#   guaranteed to be unique, they need to be treated special
#   in sort algorithms etc.
#
# rank_subterm_suffix
#   see rank_subterm, but uses the reverse list.

# TODO:
#   collect_term_ids:
#     This may be beneficial for co-occurrence search etc.
#     Accepts a list of alphabetically sorted strings.
#     The list will be prepared as a stream of common suffixes,
#     like 'Banane', -4, 'jo', -3, 'ptist' ...
#     In that way, a term search does not have to start at the
#     dictionary root,
#     but can go up just the necessary steps again and search
#     further.
#     As sorting and prefix-preparing may be quite time consuming,
#     this may not be an option everytime.
#     In addition, the collation needs to be identical.

# TODO:
#   Currently all terms have a term_id, which may limit the whole dictionary
#   to a finite number of terms (although this number can be pretty high
#   and is only limited to a single node).
#   The easiest (and recommended) solution is to treat hapax legomena
#   special.

# TODO:
#   At the moment, all terms have a same term_id mapping,
#   though different term types may have different term_id mappings.

# TODO:
#   Support case insensitivity

# TODO:
#   Support aliases (e.g. a surface term may have the
#   same postings list throughout foundries)

# TODO:
#   Add suffix_search("ig"), in case the user searches for ".*ig".
#   This may e.g. use a binary search in the suffix ranking.
#   Alternatively, if trigrams are indexed, this would of course
#   look for 'ig$'.

# TODO:
#   Although subterms will not be requested by the user, they are
#   requested, for example, by the term_id API for co-occurrence search.
#   That's why all subterms need to be stored as well.

use constant DEBUG => 1;

sub new {
  my $class = shift;
  my $file = shift;
  bless {
    file => $file,
    hash => {},   # Contain the dictionary

    # Better:
    # Only have
    # dynamic => undef,
    # static => undef,

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

    # There may be different IDs for
    # fieldvalues, fieldkeys, terms, subterms ... etc.

    # TODO: Collation needs to be defined!
    collation => undef
  }, $class;
};


sub add_term {
  my ($self, $term) = @_;

  print_log('dict', "Added term $term") if DEBUG;

  my $hash = $self->{hash};

  # Term not in dictionary yet
  unless (exists $hash->{$term}) {

    # Increment term_id
    # TODO: This may infact fail, as term_ids are limited in size.
    #   For hapax legomena, a special null marker will be returned
    my $term_id = $self->{last_term_id}++;

    # Set term to term_id
    $hash->{$term} = $term_id;

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


# Returns the term id by a term
sub term_id_by_term {
  my ($self, $term) = @_;
  print_log('dict', 'Try to retrieve term ' . $term) if DEBUG;
  return $self->{hash}->{$term};
};


# Return a list of term_ids based on a regular expression
sub term_ids {
  my ($self, $re) = @_;

  if ($re) {
    my $hash = $self->{hash};

    return sort map { $hash->{$_} } grep { $_ =~ $re } keys %$hash;
  };

  return values %{$self->{hash}};
};


# This should be implemented in the dynamic dictionary only
sub process_subterm_ranks {
  return if $_[0]->{ranked};
  my $self = shift;

  # Accept a collation for sorting
  # see
  # - https://dev.mysql.com/doc/refman/5.7/en/adding-collation.html
  # - http://www.unicode.org/reports/tr10/tr10-30.html
  my $collation = shift;

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
