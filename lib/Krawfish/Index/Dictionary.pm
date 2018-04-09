package Krawfish::Index::Dictionary;
use Krawfish::Index::Dictionary::Collations;
use Krawfish::Util::Constants qw/:PREFIX/;
use Krawfish::Util::String qw/normalize_nfkc/;
use strict;
use warnings;
use Krawfish::Log;

# This class is the basic dictionary class. It provides a
# homogeneous interface to K::I::Dictionary::Dynamic and
# K::I::Dictionary::Static (versioned).
#
# All terms need to be searched and retrieved using
# NFD normalization. NFD will leave all terms intact for
# recreation (term_by_term_id) while making it possible to
# ignore diacritica during search.
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
#   layer:       &
#   annotations
#     token      #   (not yet supported)
#     span       <>
#     relations  <, >
#     attributes @
#   fields:      +
#   fieldkeys:   !
#

#   SURFACE RANKING
#   ===============
#   The dictionary contains all ranking information for surface forms.
#   When a surface form is added, the information on the ranking in
#   the dynamic dictionary is stored as empty epsilon information initially.
#   (See the store variant of the static dictionary).
#   Every new term in the dynamic dictionary is added to a list of
#   terms with attached term ids.
#   Identical surface terms may have different sorting keys (following
#   UTS #10) - in that case, before the ranking transition, another transition
#   is added to branch on multiple sorting keys, e.g.
#   bank-[COLL-DE]-[RANKS1]-#term-id-1
#      \-[COLL-EN]-[RANKS2]-#term-id-2
#   (Or the collations are appended to the ranking level)
#   In the forward index, the different term-ids result in different rankings,
#   though they result in identical surface terms.
#   That way, different languages can be sorted at the same time solely based
#   on their sorting key.
#   BE AWARE: For checking, if a term is identical to another term,
#   the collation must be stored in a byte at the rank transition.
#   Because this may introduce quie a lot of problems, it's up to changes.
#
#   On MERGE
#     1 The dictionaries are merged
#     2 The list of new terms is sorted both in prefix and
#       suffix order according to their UTS #10 sorting keys
#     3 The sorted new term list in prefix order is merged with the
#       sorted list in prefix order of the static dictionary
#     4 When a new term is first found to be merged in,
#       the term gets the prefix rank in the merged static dictionary
#     5 All following terms are updated in the static dictionary
#       accordingly
#       (which is fast, because term-id lookup + one up is reasonable
#       fast in memory)
#     6 Do 2-5 for the suffix ordered list
#
#   The dynamic new term list (unsorted) has the following structure:
#     ([sorting-key][term_id])*  # though, this may be redundant
#   The static sorted lists have the following structure:
#     ([sorting-key-with-front-coding][term_id])*
#   Ranks are stored at the pre-terminal level in the dictionary.
#
#   Ranking information is stored on the node level
#     [term_id] -> [RANK]
#     ->rank_by_term_id(term_id)
#     ->rev_rank_by_term_id(term_id)

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
#   (THIS MAY BE OLD INFORMATION - consult Krawfish::Index::Rank)
#
#   A data structure that supports relational ordering (let's say
#   the previous term has the rank 3 and the folowing has the term
#   4 and you want to add it as 3.5) would be nice, but I wasn't
#   able to find one that's precise in all circumstances.
#   Though a Stern-Brocat-Tree may be a nice approach!
#   https://begriffs.com/posts/2018-03-20-user-defined-order.html
#
# add_field($term):
#   Identical to add_term(), but returns the term_id and a boolean value
#   if the field was set to be sortable.
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
#     - (wildcards)
#     - integer range*
#   Both dictionaries are searched (maybe in parallel).
#   * To make this work, all int fields and date fields have
#   a special data structure associated to the key identifier.
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
# rank_subterm_prefix:
#   Returns the numerical rank of a subterm in collated order.
#   The static dictionary will return a simple even numerical rank
#   (calculated on merge). The dynamic dictionary will
#   return a simple odd numerical rank. Because odd ranks are not
#   guaranteed to be unique, they need to be treated special
#   in sort algorithms etc.
#
# rank_subterm_suffix:
#   see rank_subterm, but uses the reverse list.

# TODO:
#   Create a fieldrange index
#   like http://epic.awi.de/17813/1/Sch2007br.pdf
#   This could be especially useful for dates with a specific date
#   format, like [year-byte][year-byte][month-byte][day-byte][hour-byte][minute-byte][sec-byte]
#
# TODO:
#   This should also take into account multi-ranges like described in
#   https://github.com/KorAP/Krill/issues/17
#   See also "search_range"
#     http://search.cpan.org/~davidiam/Set-SegmentTree-0.01/lib/Set/SegmentTree.pm
#     https://en.wikipedia.org/wiki/Segment_tree
#   For numeric ranges, Lucene now uses BKD trees
#     see https://issues.apache.org/jira/browse/LUCENE-6477
#     see https://users.cs.duke.edu/~pankaj/publications/papers/bkd-sstd.pdf
#     see https://github.com/deepfabric/bkdtree
#     see https://medium.com/@nickgerleman/the-bkd-tree-da19cf9493fb


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

# TODO:
#   There are two possible rank value types:
# 1 VALUE IS EVEN: The global rank from
#   the static dictionary
# 2 VALUE IS ODD: The prerank, means,
#   it is sorted based on the rank and takes the place
#   between the two rank values, but it may occurr
#   multiple types for different values.
#   This comes from the dynamic dictionary.


use constant DEBUG => 0;


# Constructor
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

    # Collations store the collation id or the field => collation association
    text_collation => undef,
    field_collation => {},
    collations => Krawfish::Index::Dictionary::Collations->new
  }, $class;
};


# Add arbitrary term to dictionary
sub add_term {
  my ($self, $term) = @_;

  # Normalize term to nfkc
  $term = normalize_nfkc($term);

  print_log('dict', "Add term $term") if DEBUG;

  my $hash = $self->{hash};

  # Term not in dictionary yet
  unless (exists $hash->{$term}) {

    # Increment term_id
    # TODO:
    #   This may in fact fail, as term_ids are limited
    #   in size.
    #   For hapax legomena, a special null marker will be returned
    my $term_id = $self->{last_term_id}++;

    # Set term to term_id
    $hash->{$term} = $term_id;

    # Store term for term_id mapping
    $self->{term_array}->[$term_id] = $term;

    print_log('dict', "New term $term is #" . $term_id) if DEBUG;
  }

  elsif (DEBUG) {
    print_log('dict', "Term $term already exists");
  };
  return $hash->{$term};
};


# Add a field to the index
# TODO:
#   Currently the collation only accepts a locale
#   but it should - in the future - probably accept a more
#   parametric definition
sub add_field {
  my ($self, $term, $locale) = @_;

  if (DEBUG) {
    print_log('dict', "Add field $term" . ($locale ? " with $locale" : ''));
  };

  # Check if term exists
  my $term_id = $self->term_id_by_term(KEY_PREF . $term);

  # The term already exists
  if ($term_id) {

    # Check which collation was stored
    my $stored_locale = $self->collation($term_id);

    # The field was not meant to be sortable
    if (!defined $locale && !defined $stored_locale) {

      # Everything is fine
      return $term_id;
    }

    # The field was meant to be sortable
    elsif (defined $locale && defined $stored_locale &&
          $locale eq $stored_locale) {

      # The collations are compatible
      return $term_id;
    };

    # Collations are not compatible
    return;
  };

  # The term does not exist yet
  $term_id = $self->add_term(KEY_PREF . $term);

  if (DEBUG) {
    print_log('dict', "Add new collation $locale to field $term_id");
  };
  $self->{field_collation}->{$term_id} = $locale;
  return $term_id;
};


# Get collations object
sub collations {
  $_[0]->{collations};
};


# Get the collation of the base or the field id or undef, if not sortable
sub collation {
  my ($self, $field_id) = @_;
  my $locale = undef;
  unless ($field_id) {
    $locale = $self->{text_collation};
  }
  else {
    $locale = $self->{field_collation}->{$field_id};
  };

  # Return the collation object
  return unless $locale;
  return 'NUM' if $locale ne 'NUM';
  return $self->{collations}->get($locale);
};



# Add subterm to dictionary
# The subterm does not need to be searched, so the mechanism is only used
# to guarantee that subterms are unique.
# There may be a better data structure for this, though.
sub add_subterm {
  my ($self, $subterm) = @_;

  warn 'DEPRECATED';

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
  warn 'DEPRECATED';
  my ($self, $subterm_id) = @_;
  print_log('dict', 'Try to retrieve subterm id ' . $subterm_id) if DEBUG;
  return $self->{subterm_array}->[$subterm_id];

};


# Returns a rank value by a certain subterm id
sub prefix_rank_by_subterm_id {
  my ($self, $subterm_id) = @_;
  $self->process_subterm_ranks;
  $self->{prefix_rank}->[$subterm_id];
};


# Returns a rank value by a certain subterm id
sub suffix_rank_by_subterm_id {
  my ($self, $subterm_id) = @_;
  $self->process_subterm_ranks;
  $self->{suffix_rank}->[$subterm_id];
};


# Returns the term id by a term
sub term_id_by_term {
  my ($self, $term) = @_;

  # Normalize term to nfkc
  $term = normalize_nfkc($term);

  print_log('dict', 'Try to retrieve term ' . $term) if DEBUG;
  return $self->{hash}->{$term};
};




# Return the last charachters of a term
# - beneficial for substring sorting
sub suffix_by_term_id {
  my ($self, $term_id, $length) = @_;
  ...
};


# Return a list of term_ids based on a regular expression
sub term_ids {
  my ($self, $re) = @_;

  # In a golang port, this should use https://golang.org/pkg/regexp/syntax/

  if ($re) {
    my $hash = $self->{hash};

    return sort map { $hash->{$_} } grep { $_ =~ $re } keys %$hash;
  };

  return values %{$self->{hash}};
};


# Returns the terms based on the internal sorting
sub terms {
  my $self = shift;
  return sort keys %{$self->{hash}};
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
