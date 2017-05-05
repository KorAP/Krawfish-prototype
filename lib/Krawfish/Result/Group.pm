package Krawfish::Result::Group;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

# TODO: Use Krawfish::Posting::Group;

# Group matches based on certain criteria, for example:
# - for record matches
#   - metadata!
#   - This is useful to group document matches for corpus browsing!
#   - BUT: This would probably need a witness mechanism, so for a match,
#     some fields can be loaded, e.g. a matching document sigle will return
#     the document title.
# - for span matches
#   - metdata
#     - this is an extension to facets, where snippet frequencies are grouped
#       based on a certain facet.
#     - having facets in a first step may improve the distributed aggregation
#       (as the central node than knows, which facets are most or least common)
#     - this grouping doesn't seem beneficial - as the facet view already helps here
#
#   - innertextual!
# - has a certain identical class on surface
# - has the same starting characters of a word
# - has the same ending characters of a word
# - has the same POS of a certain class (this is actually pretty hard!)
#   - this may mean to modify the search a bit to lift the posting types
#     and make a class, like [orth=der & base/p=*]
#   - At least the postingslist of base/p=* should be merged in parallel!
#
# This is already possible in C2 so it needs to be implemented!

# A group has the following structure for matches:
# {
#   criterion => [freq, doc_freq]
# }
#
# For docs, freq and doc_freq are identical
#
# Where criterion is a classed sequence of criteria
# with class information, like
#   1:der|2:Baum => []
# Sometimes it may indicate tokens instead of classes though ...
#
# With a witness, the group has:
# {
#   criterion => [freq, doc_freq, match]
# }
# The match can be anything - so it may even be a first example snippet.
#
# But with a compare() corpus, there may be more:
#
# {
#   criterion => [freq, doc_freq, freq, doc_freq, freq, doc_freq, ...]
# }



# WARNING!
# This kind of result can not be limited or sorted on an earlier level,
# as the number of matches is only clear after everything is aggregated.

# Construct grouping function
sub new {
  my $class = shift;
  my ($query, $criterion, $index) = @_;

  bless {
    query => $query,

    # This is a group criterion object, created outside, that defines the criterion
    criterion => $criterion,
    pos => -1,

    # Group to fill with matches and group info
    # (as class1=>X, class2=>Y)
    groups => []
  }, $class;
};


# Go through all matches
# This could, nonetheless, be implemented like Facets ...
sub _init {
  my $self = shift;

  return if $self->{init}++;

  my $criterion = $self->{criterion};

  my $query = $self->{query};

  my %groups = ();
  my ($group, $current);
  my $doc_id = -1;

  # Iterate over all queries
  while ($query->next) {

    # Get current query if there is any
    $current = $query->current or last;

    # Potentially create new group
    $group = ($groups{$criterion->get_group($current)} //= [0,0]);

    # Increment freq
    $group->[0]++;

    if ($current->doc_id != $doc_id) {

      # Increment doc_freq
      $group->[1]++;

      $doc_id = $current->doc_id;
    };
  };

  # Value is stored as [criterion, freq, doc_freq]
  # Sorted by freq by default
  my @array = ();
  foreach (sort { $groups{$b}->[0] <=> $groups{$a}->[0] } keys %groups) {
    push @array, [$_, $groups{$_}->[0], $groups{$_}->[1]];
  };

  # Store for retrieval
  $self->{groups} = \@array;
  return 1;
};


sub freq {
  my $self = shift;
  scalar @{$self->{groups}}
};

sub next {
  my $self = shift;
  $self->_init;
  if ($self->{pos}++ < ($self->freq - 1)) {
    return 1;
  };
  return;
};


sub current;


# Return a hash reference with information
sub current_group {
  my $self = shift;
  my $group = $self->{groups}->[$self->{pos}];

  # Make a hash from criterion
  return $self->{criterion}->to_hash(@$group);
};


sub to_string {
  my $self = shift;
  my $str = 'groupBy(';
  $str .= $self->{criterion}->to_string . ':';
  $str .= $self->{query}->to_string;
  return $str . ')';
};

1;
