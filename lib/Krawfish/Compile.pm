package Krawfish::Compile;
use Role::Tiny;
use strict;
use warnings;

requires qw/compile
            aggregate/;

# TODO:
#   result() should be in a separate
#   interface, so it is
#   usable in Aggregation::Base as well.

# Get result object
# TODO:
#   Identical with ::Compile
sub result {
  my $self = shift;
  if ($_[0]) {
    $self->{result} = shift;
    return $self;
  };
  $self->{result} //= Krawfish::Koral::Result->new;
  return $self->{result};
};

1;
