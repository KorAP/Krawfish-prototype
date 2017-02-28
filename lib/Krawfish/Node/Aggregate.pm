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

1;
