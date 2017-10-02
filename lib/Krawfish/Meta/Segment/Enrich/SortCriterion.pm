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
# On the node level, the relevant criteria (top_k) will be inflated,
# taken the ordering into account (which mean following matches may
# have a lot of criteria in common.
