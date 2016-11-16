package Krawfish::Info;
use strict;
use warnings;

# Add error
sub error {
  return shift->_info('error', @_);
};

sub warning {
  return shift->_info('warning', @_);
};

sub message {
  return shift->_info('message', @_);
};

# Is there an error?
sub has_error {
  return 1 if $_[0]->{error};
  return;
};


# Is there a warning?
sub has_warning {
  return 1 if $_[0]->{warning};
  return;
};


# Is there a warning?
sub has_message {
  return 1 if $_[0]->{message};
  return;
};


# Copy information from another object
sub copy_info_from {
  my ($self, $obj) = @_;

  # Copy from types
  foreach my $type (qw/error warning message/) {
    if ($obj->{$type}) {
      push @{$self->{$type} //= []}, @{$obj->{$type}};
    };
  };
};


sub _info {
  my $self = shift;
  my ($type, $code, $msg, @param) = @_;
  unless (defined $code) {
    return $self->{$type};
  };
  push(@{$self->{$type} //= []}, [$code, $msg, @param]);
  return $self;
};

1;
