package Krawfish::Cache;
use strict;
use warnings;

# Simple hash based caching system

sub new {
  my $class = shift;
  bless {}, $class;
};

sub get {
  my $self = shift;
  return $self->{shift};
};

sub set {
  my $self = shift;
  $self->{$_[0]} = $_[1];
};

1;
