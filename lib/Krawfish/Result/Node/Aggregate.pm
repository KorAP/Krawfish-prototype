package Krawfish::Node::Aggregate;
use strict;
use warnings;

# May be renamed to
# - Krawfish::MultiSegment::Aggregate
# - Krawfish::MultiNodes::Aggregate

# To aggregate top_k matches from multiple segments,
# fetch all top segments and put them in a
# priority queue. Get top match, and request the next
# match from that segment.
# Do this, until k is fine.

# Distributet results are returned from each index
# in an aggregate data section followed by result lines.
# The result lines can be returned using next_current() etc.
# while the data aggregation section is returned by the first
# call.

1;
