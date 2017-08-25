package Krawfish::Index::Fields::Rank;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless {
    collation => shift,
    prefix => [],
    suffix => [],
    plain => []
  }, $class;
};


# Add an entry to the plain list
sub add {
  my $self = shift;
  my ($value, $doc_id) = @_;
  push @{$self->{plain}}, [$value, $doc_id];
};

1;
