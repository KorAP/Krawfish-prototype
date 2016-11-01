package Krawfish::Koral::Corpus::Field;
use parent 'Krawfish::Koral::Corpus';
use strict;
use warnings;

# TODO: Check for valid parameters

sub new {
  my $class = shift;
  bless {
    type => shift,
    key => shift
  }, $class;
};

sub eq {
  my $self = shift;
  $self->{match} = 'eq';
  $self->{value} = shift;
  return $self;
};

sub ne {
  my $self = shift;
  $self->{match} = 'ne';
  $self->{value} = shift;
  return $self;
};

sub geq {
  my $self = shift;
  $self->{match} = 'geq';
  $self->{value} = shift;
  return $self;
};

sub leq {
  my $self = shift;
  $self->{match} = 'leq';
  $self->{value} = shift;
  return $self;
};

sub contains {
  my $self = shift;
  $self->{match} = 'contains';
  $self->{value} = shift;
  return $self;
};

sub excludes {
  my $self = shift;
  $self->{match} = 'excludes';
  $self->{value} = shift;
  return $self;
};


sub plan {
  ...
};


sub match {
  $_[0]->{match} // 'eq';
};

sub type {
  $_[0]->{type} // 'string';
};

sub key {
  $_[0]->{key};
};


sub value {
  $_[0]->{value};
};

sub to_koral_fragment {
  my $self = shift;

  my $field = {
    '@type' => 'koral:field',
    key => $self->key,
    match => 'match:' . $self->match,
    type => 'type:' . $self->type
  };

  # No value defined
  unless ($self->value) {

    # Check for existence
    if ($field->{match} ne 'match:contains' ||
          $field->{match} ne 'match:excludes') {

      # Set to existence default
      $field->{match} = 'match:contains';
    };
  }

  # Set value
  else {
    $field->{value} = $self->value;
  };

  return $field;
};


1;
