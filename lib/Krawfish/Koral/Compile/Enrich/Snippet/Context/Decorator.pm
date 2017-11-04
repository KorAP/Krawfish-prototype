# Some sources may have different requirements regarding the expansion size.
# To make it easier for post-filtering, this context modifier
# can add separators to the context, e.g. to restrict the visibility
# of a match to 3 sentences, even if the user asked for a whole paragraph.
#
# It can also add annotations to the match + context, e.g. to add
# pagebreaks.
#
# The decorator will start at the beginning of the left context and
# move till the end of the right context.
#
# All annotations may be added as milestones.
#
# A special decorator will add empty elements for every word.
