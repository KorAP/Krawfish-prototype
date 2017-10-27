package Krawfish::Query::Reference;
use parent 'Krawfish::Query';
use Krawfish::Log;
use strict;
use warnings;

# TODO:
#   This is not an actual query,
#   but a pointer to a query buffer.
#
#   Maybe use a Util::MultiBuffer

# Support a BufferedRef query mechanism,
# that will be used for identical subqueries.
# This is especially important for filtering.
# This Buffered Reference supports multiple
# fingers at different positions in the query.

# The ring buffer query is well suited for this.

# Constructor
sub new {
  my $class = shift;

  # This is a buffered query
  my $query = shift;

  # Get signature
  my $sig = $query->signature;
  bless {
    query => shift,
  }, $class;
};


# Clone query
sub clone {
  ...
};


# Move to next posting
sub next {
  ...
};


# Stringification
sub to_string {
  my $self = shift;
};


# Get maximum frequency
sub max_freq {
  ...
};


# Filter query by VC
sub filter_by {
  ...
};


sub requires_filter {
  ...
};

1;
