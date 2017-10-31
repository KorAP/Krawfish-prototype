package Krawfish::Koral::Report;
use Role::Tiny;
use strict;
use warnings;
use Krawfish::Log;
requires qw/error warning message has_error has_warning has_message/;

# Report on errors, warnings an anything else

use constant DEBUG => 0;


# Add error
sub error {
  my $self = shift;
  print_log('info', 'Error: ' . join(' ', @_)) if DEBUG;
  return $self->_info('error', @_);
};


# Add warning
sub warning {
  my $self = shift;
  print_log('info', 'Warning: ' . join(' ', @_)) if DEBUG;
  return $self->_info('warning', @_);
};


# Add message
sub message {
  my $self = shift;
  print_log('info', 'Message: ' . join(' ', @_)) if DEBUG;
  return $self->_info('message', @_);
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
# Function
sub copy_info_from {
  my ($self, $obj) = @_;

  # Copy from types
  foreach my $type (qw/error warning message/) {
    if ($obj->{$type}) {
      push @{$self->{$type} //= []}, @{$obj->{$type}};
    };
  };
};


# Copy information from another object
sub remove_info_from {
  my ($self, $obj) = @_;

  # Copy from types
  foreach my $type (qw/error warning message/) {
    if ($obj->{$type}) {
      push @{$self->{$type} //= []}, @{$obj->{$type}};
      delete $obj->{$type};
    };
  };
};


# Merge infos with a new object
sub merge_info {
  my ($self, $target) = @_;
  copy_info_from($target, $self);
};


# Information
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
