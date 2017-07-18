# Create a fieldrange index
# like http://epic.awi.de/17813/1/Sch2007br.pdf
# This could be especially useful for dates with a specific date
# format, like [year-byte][year-byte][month-byte][day-byte][hour-byte][minute-byte][sec-byte]
#
# TODO:
#   This should also take into account multi-ranges like described in
#   https://github.com/KorAP/Krill/issues/17
#
# http://search.cpan.org/~davidiam/Set-SegmentTree-0.01/lib/Set/SegmentTree.pm
# https://en.wikipedia.org/wiki/Segment_tree
