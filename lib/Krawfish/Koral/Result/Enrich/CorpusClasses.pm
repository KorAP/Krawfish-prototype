package Krawfish::Koral::Result::Enrich::CorpusClasses;
use strict;
use warnings;
use Role::Tiny::With;

with 'Krawfish::Koral::Report';
with 'Krawfish::Koral::Result::Inflatable';

# The classes are only numbers (1..15)

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
