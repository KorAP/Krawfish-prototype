package Krawfish::Result::Segment::Enrich::TermIDs;
use parent 'Krawfish::Result';
use Krawfish::Log;
use strict;
use warnings;

# Enrich each match with all term ids for a specific region and
# for a specific class

# TODO:
#   Move Fields, Snippet, TermIDs to
#   Krawfish::Result::Segment::Enrich::*
#   Because they enrich matches.
#   Or create K::R::S::Match::* because
#   they change each match

# TODO:
#   Make this usable for Krawfish::Result::Group::Classes
#   by supporting $nrs instead of $nr
#
# TODO:
#   Classes may overlap, so subtokens should be cached
#   or rather memoized!
#
# TODO:
#   For a class there may be more than one start+end values.
#   For sorting, gaps should be recognized and marked
#   with a term_id=0.
#   For sorting it's important to remember that!

use constant {
  DEBUG => 0,
    NR => 0,
    START_POS => 1,
    END_POS => 2,
};


sub new {
  my $class = shift;
  bless {
    index => shift,
    query => shift,
    nr => shift // 0,
    match => undef
  }, $class;
};


# Get the current match
sub current_match {
  my $self = shift;

  # Current match is already defined
  if ($self->{match}) {

    # Return match
    return $self->{match};
  };

  # Get match based on current query position
  my $match = $self->match_from_query;

  # Get tzhe subtokens object to retrieve term ids
  my $subtokens = $self->{index}->subtokens;

  my ($start, $end) = ();

  # Class has match scope
  unless ($self->{nr}) {
    $start = $match->start;
    $end = $match->end;
  }

  # Specific class scope
  else {
    my ($class) = $match->get_classes([$self->{nr}]);
    $start = $class->[1];
    $end   = $class->[2];
  };

  # Get term ids for the specific match positions
  my $term_ids = $subtokens->get_term_ids($match->doc_id, $start, $end);

  # Set term ids for specific class
  $match->term_ids($self->{nr} => $term_ids);

  # Set match
  $self->{match} = $match;
};


# Next match
sub next {
  my $self = shift;
  $self->{match} = undef;
  return $self->{query}->next;
};


1;
