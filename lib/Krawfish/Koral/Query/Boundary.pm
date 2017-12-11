package Krawfish::Koral::Query::Boundary;
use Role::Tiny;
use strict;
use warnings;

# Serialization helper
sub to_koral_boundary {
  my $self = shift;
  my %hash = (
    '@type' => 'koral:boundary'
  );
  $hash{min} = $self->{min} if defined $self->{min};
  $hash{max} = $self->{max} if defined $self->{max};
  return \%hash;
};


# Deserialization helper
sub from_koral_boundary {
  my ($class, $kq) = @_;

  my ($min, $max);
  if ($kq->{min}) {
    $min = $kq->{min};
  };
  if ($kq->{max}) {
    $max = $kq->{max};
  };

  return ($min, $max);
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
