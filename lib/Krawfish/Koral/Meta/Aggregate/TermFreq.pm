package Krawfish::Koral::Meta::Aggregate::TermFreq;
use strict;
use warnings;

# TODO:
#   This is rather a group query than an aggregation query.

# This calls Krawfish::Result::Segment::Aggregate::TermFreq.
# It is used (among other things) for Co-Occurrence Search.
#
# It will return, for a list of terms, the frequency of the terms
# in a given corpus.
#
# This may mean that the aggregation is not part of the meta-query but per term
# so it wraps around termFreq(#4)|termFreq(#5)|termFreq(#6)...
# It could als be used like a filter, calling ->term_id on each match
# and then skipping to the next document
#
# It may even be beneficial to have a special

sub new {
  my $class = shift;
  my $self = '';
  bless \$self, $class;
};

sub type {
  'freq'
};

sub identify {
  $_[0];
};

sub normalize {
  $_[0];
};

sub to_string {
  'termfreq';
};

1;
