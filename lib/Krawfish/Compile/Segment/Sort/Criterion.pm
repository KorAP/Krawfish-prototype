package Krawfish::Compile::Segment::Sort::Criterion;
use Krawfish::Koral::Result::Enrich::SortCriterion;
use Krawfish::Log;
use strict;
use warnings;
use Role::Tiny;

use constant DEBUG => 1;

# TODO:
#   On the segment level, it's enough to compare on the ranks,
#   but it's also necessary to enrich with the fields
#   to have the necessary enrichment when moving to the cluster
#   (at least having the collation comparation key).
#   To make this work in multivalued fields, the fields
#   would
#
#     a) need to be sorted in alphabetic or numeric order
#     b) the ranking sorted field is indexed

# TODO:
#   This may very well be in Krawfish::Compile::Enrich::SortCriterion;

# TODO:
#   This currently only works for fields!


# Implement new current match
sub current_match {
  my $self = shift;

  my $match = $self->match_from_query or return;

  if (DEBUG) {
    print_log('compile', 'Current match is ' . $match->to_string);
  };

  my $criterion;
  if ($match->doc_id == $self->{last_doc_id}) {
    $criterion = $self->{last_criterion};
  }

  else {

    # 1. Take the rank of the match
    # 2. Check, if the rank is equal to max_rank + 1
    #    (meaning no criterion)
    # 3. Otherwise get the nth value from the sorted rank field
    #    can either be a number or a comparation value

    
    # Create criterion
    my $criterion = Krawfish::Koral::Result::Enrich::SortCriterion->new(
      $self->criterion
    );

  };


  # Enrich with criterion
  # $match->add($criterion);

  return $match;
};


1;
