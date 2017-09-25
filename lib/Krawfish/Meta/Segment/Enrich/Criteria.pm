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
# lists and create a new sorted list in match order (or to somehow
# keep match order) to make it possible to enrich with all
# sorting criteria.
# Otherwise - sometimes the sorting may remember "witnesses" for
# sorted bundles.
