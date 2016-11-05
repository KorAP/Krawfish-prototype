package Krawfish::Information;
use strict;
use warnings;

# Add error
sub error {
  my $self = shift;
  my ($code, $msg, @param) = @_;
  push(@{$self->{error} //= []}, [$code, $msg, @param]);
  return $self;
};

sub has_error {
  return 1 if $_[0]->{error};
  return;
};

# sub warning;
# sub errors;

1;
