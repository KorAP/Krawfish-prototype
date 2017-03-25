package Krawfish::Corpus::DocVector;
use parent 'Krawfish::Corpus';
use strict;
use warnings;

# Accepts a vector of UIDs, that are translated
# to a sorted vector of document IDs to be used in
# a corpus query.
# This requires fast translation of UID->ID to be
# more efficient than merging with an or() operator.
#
# This can be used, e.g., for tagged corpora.

sub new {
  my ($class, $index, $vector) = @_;
  bless {
    vector => $vector
  }, $class;
};

sub next;

sub current;

sub freq;

sub to_string;

1;
