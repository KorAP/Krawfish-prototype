package Krawfish::Posting::Ranks;
use Role::Tiny;
use strict;
use warnings;

# Remember ranks per match, so enrichment is easier

# Set individual rank
sub set_rank {
  my ($self, $level, $rank) = @_;
  $self->{ranks} //= [];
  $self->{ranks}->[$level] = $rank;
};


# Get or set ranks
sub ranks {
  my $self = shift;
  if (@_) {
    $self->{ranks} = [@_];
    return $self;
  };
  return () unless defined $self->{ranks};
  return @{$self->{ranks}};
};


1;
