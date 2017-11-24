package Krawfish::Posting::Ranks;
use Role::Tiny;
use strict;
use warnings;

# Remember ranks per match, so enrichment is easier

# TODO:
#   This may not be relevant for enrichment of criteria!

# Set individual rank
sub rank {
  my ($self, $level, $rank) = @_;

  # Set rank
  if (defined $rank) {
    $self->{ranks} //= [];
    $self->{ranks}->[$level] = $rank;
  }

  # Get rank
  else {
    return $self->{ranks}->[$level] // 0;
  };
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
