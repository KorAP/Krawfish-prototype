package Krawfish::Koral::Query::Boundary;
use Role::Tiny;
use strict;
use warnings;

# Serialization helper
sub boundary {
  my $self = shift;
  my %hash = (
    '@type' => 'koral:boundary'
  );
  $hash{min} = $self->{min} if defined $self->{min};
  $hash{max} = $self->{max} if defined $self->{max};
  return \%hash;
};


sub min {
  if (defined $_[1]) {
    $_[0]->{min} = $_[1];
    return $_[0];
  };
  $_[0]->{min};
};


sub max {
  if (defined $_[1]) {
    $_[0]->{max} = $_[1];
    return $_[0];
  };
  $_[0]->{max};
};


1;
