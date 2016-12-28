package Krawfish::Koral::Corpus::Field;
use parent 'Krawfish::Koral::Corpus';
use Krawfish::Corpus::Field;
use Krawfish::Corpus::Negation;
use strict;
use warnings;

# TODO: Check for valid parameters

sub new {
  my $class = shift;
  bless {
    key_type => shift,
    key => shift
  }, $class;
};

sub type {
  'field';
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
  $self->is_negative(1);
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


sub plan_for {
  my ($self, $index) = @_;

  # Negative field
  if ($self->is_negative) {
    return Krawfish::Corpus::Negation->new(
      $index,
      Krawfish::Corpus::Field->new(
        $index,
        $self->to_term
      )
    );
  };

  # Positive field
  Krawfish::Corpus::Field->new(
    $index,
    $self->to_term
  );
};


sub match {
  $_[0]->{match} // 'eq';
};

sub key_type {
  $_[0]->{key_type} // 'string';
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
    type => 'type:' . $self->key_type
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


sub to_string {
  my $self = shift;
  my $str = $self->{key};
  my $op = $self->match;
  if ($op eq 'eq') {
    $str .= '=';
  }
  elsif ($op eq 'ne') {
    $str .= '!=';
  }
  elsif ($op eq 'geq') {
    $str .= '>=';
  }
  elsif ($op eq 'leq') {
    $str .= '<=';
  }
  elsif ($op eq 'contains') {
    $str .= '~'
  }
  elsif ($op eq 'excludes') {
    $str .= '!=';
  }
  else {
    $str .= '?';
  };
  return $str . $self->{value};
};

sub to_term {
  my $self = shift;
  my $term = $self->to_string;
  $term =~ s/^([^=!><~\?]+?)(?:[!<>]?[=~\?])/$1:/;
  return $term;
};

1;
