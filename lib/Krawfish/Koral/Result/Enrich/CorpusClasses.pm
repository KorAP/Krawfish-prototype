package Krawfish::Koral::Result::Enrich::CorpusClasses;
use strict;
use warnings;

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


# Key for enrichment
sub key {
  'inCorpus';
};


# Stringification
sub to_string {
  my $self = shift;
  return 'inCorpus:' . join(',', @{$self->{classes}});
};


# Serialize to KoralQuery
sub to_koral_fragment {
  $_[0]->{classes};
};

1;
