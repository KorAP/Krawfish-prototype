package Krawfish::Koral::Corpus::Static;
use Role::Tiny::With;
use strict;
use warnings;

with 'Krawfish::Koral::Corpus';

# Accepts an identifier to a static virtual corpus query
# (e.g. a list of text/Siglen), represented as a normalized
# KoralQuery file on disc.

sub new {
  my $class = shift;
  bless {
    id => shift
  }, $class;
};

# Do nothing
sub normalize {
  $_[0];
};

# Check if the ID is cached. In case it is cached,
# Return the cache query.
sub memoize {
  ...
};

# Load the KoralQuery file, optimize the query,
# and wrap it in a cache for the next type it is consulted.
# The query is already normalized.
# This should only be loaded by some segments with updates.
sub optimize {
  ...
};


sub operands {
  ...
};

1;
