package Krawfish::Result::Segment::Aggregate::Count;
use parent 'Krawfish::Result::Segment::Aggregate::Base';
use Krawfish::Log;
use strict;
use warnings;

# TODO: Rename to frequencies
# TODO: Support virtual corpus classes

use constant DEBUG => 0;

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
  'count'
};

1;
