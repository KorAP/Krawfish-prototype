package Krawfish::Info;
use strict;
use warnings;

# Add error
sub error {
  my $self = shift;
  my ($code, $msg, @param) = @_;
  push(@{$self->{error} //= []}, [$code, $msg, @param]);
  return $self;
};


# Is there an error?
sub has_error {
  return 1 if $_[0]->{error};
  return;
};


# Copy information from another object
sub copy_info_from {
  my ($self, $obj) = @_;
  if ($obj->has_error) {
    push @{$self->{error} //= []}, @{$obj->{error}};
  };
};

# sub warning;
# sub errors;

1;
