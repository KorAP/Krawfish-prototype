package Krawfish::Compile::Segment::Enrich::SortCriterion;
use parent 'Krawfish::Compile';
use warnings;
use strict;

# Enrich an item with sort criteria.
# This is necessary to sort items beyond the segment.
# The problem with this enrichment is,
# that it needs to augment the sorted items after sorting,
# so they are not in a proper order to go through
# the fields lists (for example) to collect the field values
# or through the forward index to collect term_ids (though
# this may be a different API).
#
# A proper way to do this would be to go through the sorted
# lists and create a new sorted list in doc order (or to somehow
# keep match order) to make it possible to enrich with all
# sorting criteria.
#
# 1. For Fields: Create a list of all docs to enrich in doc_id order
#    (Ignore duplicates)
# 2. Prepare all requested fields in field order
# 3. Go through all fields and collect values or term_ids
# 4. Create criterion vectors per match based on these information
#
# But:
# It may very well be possible to only enrich if required
# on the node level.
#
# On the node level, the relevant criteria (top_k) will be inflated,
# taken the ordering into account (which means following matches may
# have a lot of criteria in common.


sub new {
  my $class = shift;
  bless {
    query => shift,

    # Store all criteria in sorted order,
    # which may include terms and fields.
    # This will also keep the direction
    # and possibly the collation.
    criteria => shift
  }, $class
};

sub _init {
  my $self = shift;

  return if $self->{init}++;

  # TODO:
  #   Go through all criteria and collect required field IDs.
  #   Bring required field IDs in order.
  #   Create an array for field_id => criterion_position to
  #   map the surface term to the criterion after fetching.
  #   Remember the criterion position for optional term sorting.
};


sub current_match {
  # TODO:
  #   Create an empty list for sorting criteria.
  #   a) Retrieve for the document id all the relevant fields
  #      if there are fields to retrieve.
  #      Add in the position of the criteria list.
  #   b) The surface term is already retrieved and enriched.
  #      Add in the position of the criteria list.
};


1;
