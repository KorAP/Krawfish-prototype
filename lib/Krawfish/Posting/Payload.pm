package Krawfish::Posting::Payload;
use parent 'Exporter';
use strict;
use warnings;
use Scalar::Util qw/blessed/;


# Class representing payload data


use constant {
  PTI_CLASS => 0
};

our (@EXPORT);

@EXPORT = qw/PTI_CLASS/;


# Constructor
sub new {
  my $class = shift;
  bless [], $class;
};


# Get length of payload
sub length {
  scalar @{$_[0]};
};


# Copy data from other payload
sub copy_from {
  my ($self, $payload) = @_;
  foreach (@$payload) {
    $self->add(@$_);
  };
  return $self;
};


# Add data to payload
sub add {
  my $self = shift;
  push @{$self}, [@_];
  return $self;
};


# Clone payload
sub clone {
  my $self = shift;
  my $new = __PACKAGE__->new;
  foreach (@$self) {
    $new->add(@$_);
  };
  return $new;
};


# Stringification
sub to_string {
  my $self = shift;
  return join ('|', map { join(',', @{$_}) } @$self );
};


# Get as array
sub to_array {
  @{$_[0]};
};

1;
