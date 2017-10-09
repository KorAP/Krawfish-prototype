package Krawfish::Compile::Segment::Aggregate::Frequencies;
use parent 'Krawfish::Compile::Segment::Aggregate::Base';
use Krawfish::Log;
use strict;
use warnings;

# Count the frequencies of all matches of the query
# per doc and per match

# TODO:
#   Support virtual corpus classes

# Add to totalResources immediately
sub each_doc {
  $_[2]->{totalResources}++;
};


# Add to totalResults immediately
sub each_match {
  $_[2]->{totalResults}++;
};


# Stringification
sub to_string {
  'freq'
};

1;

