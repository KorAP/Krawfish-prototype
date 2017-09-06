package Krawfish::Util::SetCount;
use strict;
use warnings;

# Create a set count, that will take int32 values
# (e.g. term ids) and associate numerical data.
# Instead of hashing, it is probably beneficial
# to use a byte trie to store the data, see e.g.
# https://github.com/samgiles/bytetrie

sub new {
  my $class = shift;
  bless {}, $class;
};


# Increment key value
sub incr {
  my ($self, $key) = @_;
  $self->{$key}++;
};


# Add key value
sub add {
  my ($self, $key, $value) = @_;
  $self->{$key} += $value;
};


# Get the value for a certain key
sub get {
  my ($self, $key) = @_;
  return $self->{$key};
};


# Get all keys associated with their value
sub all {
  my $self = shift;
  return each %$self;
};

1;
