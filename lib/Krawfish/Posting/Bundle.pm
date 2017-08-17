package Krawfish::Posting::Bundle;
use parent 'Krawfish::Posting';
use overload '""' => sub { $_[0]->to_string }, fallback => 1;
use warnings;
use strict;

# TODO:
#   This is quite similar to K::P::Group

# This is a container class for multiple Krawfish::Posting objects,
# used for (among others) sorting.

# Constructor
sub new {

  # Bless an array
  my $self = bless [], shift;
  foreach (@_) {
    unless ($self->add($_)) {
      warn "$_ is not a valid match object";
      return;
    };
  };
  $self;
};


# Return document id of the bundle
sub doc_id {
  return unless $_[0]->length;
  $_[0]->[0]->doc_id;
};


# Start position not available
sub start {
  warn 'Not available on bundle';
  0;
};


# End position not available
sub end {
  warn 'Not available on bundle';
  0;
};


# Clone posting object
sub clone {
  my $self = shift;
  return __PACKAGE__->new(@$self);
};


# Payload not really available
sub payload {
  Krawfish::Posting::Payload->new;
};


# Return length
sub length {
  scalar @{$_[0]};
};


# Add match to match array
sub add {
  my ($self, $obj) = @_;

  # Not an object
  return unless $obj;

  # Push object to list
  if ($obj->isa('Krawfish::Posting')) {
    push @$self, $obj;
    return 1;
  };
  return;
};


# Stringify bundle
sub to_string {
  my $self = shift;
  return '[' . join ('|', map { $_->to_string } @$self) . ']';
};


# Unbundle bundle
sub unbundle {
  return @{$_[0]};
};


1;
