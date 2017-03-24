package Krawfish::Posting::Bundle;
use overload '""' => sub { $_[0]->to_string }, fallback => 1;
use warnings;
use strict;

# This is a container class for multiple Krawfish::Posting objects

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

sub doc_id {
  $_[0]->[0]->doc_id;
};


# Return length
sub length {
  scalar @{$_[0]};
};


# Add match to match array
sub add {
  my ($self, $obj) = @_;
  return unless $obj;
  if ($obj->isa('Krawfish::Posting')) {
    push @$self, $obj;
    return 1;
  };
  return;
};


# Stringify bundle
sub to_string {
  my $self = shift;
  return join ('', map { $_->to_string } @$self);
};


1;
