package Krawfish::Koral::Query::Filter;
use strict;
use warnings;

# The filter will filter a query based on a virtual corpus.
# First the filter is always on the root of the query.
#
# filter(author=goethe,[Der][alte&ADJ][Mann])
#
# In the normalization phase, this will probably not change
# much.
#
# In the optimization phase, in queries where ordering is key
# (like and-queries), the filter will be adopted to the rarest
# operand.
#
# next([Der],previous(filter(author=goethe,[Mann]),[alte&ADJ]))

__END__
