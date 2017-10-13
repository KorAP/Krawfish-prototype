package Krawfish::Corpus::DocVector;
use parent 'Krawfish::Corpus';
use strict;
use warnings;

# Accepts a vector of UIDs, that are translated
# to a sorted vector of document IDs to be used in
# a corpus query.
#
# This can be used, e.g., for tagged corpora.
#
# It may also be required for COSMAS II virtual
# corpora.

sub new {
  my ($class, $index, $vector) = @_;
  bless {
    vector => $vector
  }, $class;
};


# The query is built by iterating through all terms
# in the dictionary and fetching the relevant doc_ids per
# segment. While doing that, the doc_ids are sorted and
# resulting in an index vector.
sub _init {
  ...
};


# Move to next posting
sub next {
  ...
};


# Get current posting
sub current {
  ...
};


# Get maximum frequency
sub max_freq {
  ...
};


# Stringification
sub to_string {
  ...
};

1;
