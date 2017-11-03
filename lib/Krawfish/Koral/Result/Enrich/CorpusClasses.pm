package Krawfish::Koral::Result::Enrich::CorpusClasses;
use strict;
use warnings;
use Role::Tiny::With;

with 'Krawfish::Koral::Result::Inflatable';

# Enrich with class numbers.
# The classes are simple numbers (1..15).
# The match class (0) is ignored.

# Constructor
sub new {
  my $class = shift;
  bless {
    classes => [@_]
  }, $class;
};


# Nothing to do
sub inflate {
  $_[0];
};

# Stringification
sub to_string {
  my $self = shift;
  return 'inCorpus:' . join(',', @{$self->{classes}});
};


# Key for enrichment
sub key {
  'inCorpus';
};


# Serialize to KoralQuery
sub to_koral_fragment {
  $_[0]->{classes};
};

1;
