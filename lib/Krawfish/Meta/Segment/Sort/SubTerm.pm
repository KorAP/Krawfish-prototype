package Krawfish::Meta::Segment::Sort::SubTerm;
use strict;
use warnings;

# This will sort based on a pre-ranked subterm
# or rather a subterm list for a class
#
# A given node-wide vector_ref can be used to limit
# the list of terms to check.
#
# As classes are in order, a sortafter on subterms
# for further classes are only relevant in case
# there are matches with identical ranks on this class.

sub new {
  my $class = shift;

  # TODO:
  #   Possibly remember the collation
  my $self = bless {
    index      => shift,
    suffix     => shift // 0,
    descending => shift // 0,
    class      => shift // 0,
    max_rank_vector_ref => shift // []
  }, $class;

  # Get ranking
  $self->{dict} = $self->{index}->dictionary or return;

  # Get maximum rank if descending order
  $self->{max} = $self->{ranks}->max if $self->{descending};

  return $self;
};


# Check for the rank of the match if it is smaller
# than the given rank.
sub rank_lt {
  my ($self, $match) = shift;

  # TODO:
  #   For the requested class(es),
  #   retrieve the subterm_ids.
  #   This is similar to Enrich::Snippet retrieval,
  #   as classes may have overlaps.
  #   go through all terms in either left-to-right (prefix)
  #   or right-to-left (suffix) order and rank as long as
  #   the terms are littler than the rank vector

  my $rank;
  if ($self->{suffix}) {
    $rank = $self->{dict}->suffix_rank_by_subterm_id($subterm_id);
  }
  else {
    $rank = $self->{dict}->prefix_rank_by_subterm_id($subterm_id);
  };

  # Revert if maximum rank is set
  return $max ? $max - $rank : $rank;
};


1;
