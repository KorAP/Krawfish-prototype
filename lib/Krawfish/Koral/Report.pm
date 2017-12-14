package Krawfish::Koral::Report;
use strict;
use warnings;
use Role::Tiny;
use Krawfish::Log;

requires qw/error
            warning
            message
            has_error
            has_warning
            has_message/;

# Report on errors, warnings an anything else

use constant {
  CONTEXT => 'http://korap.ids-mannheim.de/ns/koral/0.6/context.jsonld',
  DEBUG => 0
};


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

  $self;
};


# Copy information from another object
sub move_info_from {
  my ($self, $obj) = @_;

  # Copy from types
  foreach my $type (qw/error warning message/) {
    if ($obj->{$type}) {
      push @{$self->{$type} //= []}, @{$obj->{$type}};
      delete $obj->{$type};
    };
  };

  $self;
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


sub to_koral_report {
  my ($self, $type) = @_;
  return $self->_info($type);
};


# Wrap the fragment in context
sub to_koral_query {
  my $self = shift;
  my $koral = $self->to_koral_fragment;
  $koral->{'@context'} = CONTEXT;

  # Add potential warnings
  if ($self->has_warning) {
    $koral->{warnings} = $self->to_koral_report('warning')
  };

  # Add potential errors
  if ($self->has_error) {
    $koral->{errors} = $self->to_koral_report('error')
  };

  # Add potential messages
  if ($self->has_message) {
    $koral->{messages} = $self->to_koral_report('message')
  };

  return $koral;
};



1;
