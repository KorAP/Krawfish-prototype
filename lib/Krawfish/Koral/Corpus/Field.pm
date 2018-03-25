package Krawfish::Koral::Corpus::Field;
use Krawfish::Koral::Corpus::FieldID;
use Role::Tiny;
use strict;
use warnings;

use constant DEBUG => 0;

# TODO:
#   - Check for valid parameters
#   - Only support positive terms
#   - Wrap in negative field!

sub type {
  'field';
};

sub is_leaf { 1 };

# Equal
sub eq {
  my $self = shift;
  $self->{match} = 'eq';
  $self->value(shift) or return;
  return $self;
};


# Not equal
sub ne {
  my $self = shift;
  $self->{match} = 'eq';
  $self->is_negative(1);
  $self->value(shift) or return;
  return $self;
};


# Check for negativity
sub is_negative {
  my $self = shift;
  if (scalar @_ == 1) {
    $self->{negative} = shift;

    my $op = $self->match;
    if ($self->{negative}) {

      # Reverse operation
      if ($op eq 'eq') {
        $self->{match} = 'ne';
      }
      elsif ($op eq 'contains') {
        $self->{match} = 'excludes'
      };
    }

    else {

      # Reverse operation
      if ($op eq 'ne') {
        $self->{match} = 'eq';
      }
      elsif ($op eq 'excludes') {
        $self->{match} = 'contains'
      };
    };
  };
  return $self->{negative} // 0;
};


# Contains the value in multi-token field
sub contains {
  my $self = shift;
  $self->{match} = 'contains';
  $self->value(shift) or return;
  return $self;
};


# Does not contain the value in multi-token field
sub excludes {
  my $self = shift;
  $self->{match} = 'excludes';
  $self->value(shift) or return;
  return $self;
};

sub can_toggle_negativity {
  ...
};


sub optimize {
  'Irrelevant';
};


sub operands {
  return [];
};


# TODO: Support existence
sub match {
  my $self = shift;
  if (@_) {
    $self->{match} = shift;
    return $self;
  };
  return ($self->{match} // 'eq');
};


sub key {
  $_[0]->{key};
};


sub value {
  my $self = shift;
  if (@_) {
    $self->{value} = shift;
    return $self;
  };
  return $self->{value};
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


# Stringification
sub to_string {
  my $self = shift;

  return 0 if $self->is_null;

  my $str = ''; # $self->key_type . ':';
  $str .= $self->{key};
  my $op = $self->match;

  unless ($self->{value}) {
    return $str unless $op eq 'excludes';
    return $str; # KEY_PREF . $str;
  };

  $str .= $self->match_short;

  return $str . $self->value_string;
};


sub value_string {
  $_[0]->{value};
};

sub match_short {
  my $self = shift;
  my $op = $self->match;
  if ($op eq 'eq') {
    return '=';
  }
  elsif ($op eq 'ne') {
    return '!=';
  }
  elsif ($op eq 'geq') {
    return '>=';
  }
  elsif ($op eq 'leq') {
    return '<=';
  }
  elsif ($op eq 'contains') {
    return '~'
  }
  elsif ($op eq 'excludes') {
    return '!=';
  };
  return '?';
};


# Stringification for sorting
sub to_sort_string {
  # TODO:
  #   Maybe date, string etc. implementations are generalizable!
  return $_[0]->to_string;
};

sub is_relational {
  return 0;
};

sub to_term {
  my $self = shift;
  my $term = $self->to_string;
  $term =~ s/^([^=!><~\?]+?)(?:[!<>]?[=~\?])/$1:/;
  return $term;
};


sub from_koral {
  ...
};

sub to_neutral {
  $_[0]->to_term;
};



1;
