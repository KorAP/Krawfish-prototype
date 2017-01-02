package Krawfish::Result::Aggregate::Count;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

sub new {
  my $class = shift;
  bless {
    doc_freq => 0,
    freq     => 0
  }, $class;
};


# Only preload if necessary
sub each_doc {
  $_[0]->{doc_freq}++;
};


sub each_match {
  $_[0]->{freq}++;
};


sub doc_freq {
  $_[0]->{doc_freq}
};

sub freq {
  $_[0]->{freq}
};

sub result {
  my $self = shift;
  return {
    totalResults => $self->{freq},
    totalResources => $self->{doc_freq}
  };
};

sub to_string {
  'count'
};

1;
