package Krawfish::Koral::Corpus::Field;
use parent 'Krawfish::Koral::Corpus';
use Krawfish::Koral::Corpus::FieldID;
use strict;
use warnings;

use constant DEBUG => 0;

# TODO:
#   - Check for valid parameters
#   - Only support positive terms
#   - Wrap in negative field!

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

sub is_leaf { 1 };

# Equal
sub eq {
  my $self = shift;
  $self->{match} = 'eq';
  $self->{value} = shift;
  return $self;
};


# Not equal
sub ne {
  my $self = shift;
  $self->{match} = 'eq';
  $self->{value} = shift;
  $self->is_negative(1);
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


# Contains the value in multi-token field
sub contains {
  my $self = shift;
  $self->{match} = 'contains';
  $self->{value} = shift;
  return $self;
};


# Does not contain the value in multi-token field
sub excludes {
  my $self = shift;
  $self->{match} = 'excludes';
  $self->{value} = shift;
  return $self;
};

sub can_toggle_negativity;


sub inflate {
  # Inflate for RegEx and existence!
  warn 'Inflation on fields not yet implemented';
  return $_[0];
};


# This is alternative to inflate
sub identify {
  my ($self, $dict) = @_;

  # Do not inflate
  # TODO:
  #   But identify!!!
  unless ($self->is_regex) {

    my $term = $self->to_term;

    print_log('kq_term', "Translate term $term to term_id") if DEBUG;

    my $term_id = $dict->term_id_by_term2('+' . $term);
    return Krawfish::Koral::Corpus::FieldID->new($term_id);
  };

  warn 'Inflation on regex not yet supported!';
  return;
};



sub operands {
  return [];
};


# TODO:
#   Support regular expressions!
sub is_regex {
  0;
};


sub optimize {
  my ($self, $index) = @_;

  warn 'Optimization not supported!';

  # Negative field
  if ($self->is_negative) {
    warn 'Fields are not allowed to be negative';
    return;
  };

  # Positive field
  my $query = Krawfish::Corpus::Field->new(
    $index,
    $self->to_term
  );

  if ($query->max_freq == 0) {
    return Krawfish::Query::Nothing->new;
  };

  return $query;
};


sub match {
  # TODO: Support existence
  return ($_[0]->{match} // 'eq');
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

  return 0 if $self->is_null;

  my $str = $self->{key};
  my $op = $self->match;

  unless ($self->{value}) {
    return $str unless $op eq 'excludes';
    return '!' . $str;
  };

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


sub to_neutral {
  $_[0]->to_term;
};


1;
