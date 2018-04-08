package Krawfish::Koral::Corpus::Field::Date;
use Krawfish::Util::Constants ':PREFIX';
use Krawfish::Log;
use Role::Tiny::With;
use strict;
use warnings;

with 'Krawfish::Koral::Corpus::Field';
with 'Krawfish::Koral::Corpus::Field::Relational';
with 'Krawfish::Koral::Corpus';

use constant DEBUG => 0;

# TODO:
#   A date should probably have a different prefix

# TODO:
#   Compare with de.ids_mannheim.korap.util.KrillDate

# Construct new date field object
sub new {
  my $class = shift;
  bless {
    key => shift,
    parsed => undef,
    year => undef,
    month => undef,
    day => undef
  }, $class;
};


sub key_type {
  'date';
};

sub year {
  $_[0]->{year};
};

sub month {
  $_[0]->{month} // 0;
};

sub day {
  $_[0]->{day} // 0;
};

sub value_geq {
  my ($self, $other) = @_;
  if ($self->year > $other->year) {
    return 1;
  }
  elsif ($self->year < $other->year) {
    return 0;
  }
  elsif (!$other->month) {
    return 1;
  }
  elsif ($self->month > $other->month) {
    return 1;
  }
  elsif ($self->month < $other->month) {
    return 0;
  }
  elsif (!$other->day) {
    return 1;
  }
  elsif ($self->day > $other->day) {
    return 1;
  };
  return 0;
};


# Translate all terms to term ids
sub identify {
  my ($self, $dict) = @_;

  if ($self->match_short ne '=') {
    warn 'Relational matches not supported yet';
    return;
  };

  my $term = $self->to_term;

  print_log('kq_date', "Translate term $term to term_id") if DEBUG;

  my $term_id = $dict->term_id_by_term(DATE_FIELD_PREF . $term);

  return $self->builder->nowhere unless defined $term_id;

  return Krawfish::Koral::Corpus::FieldID->new($term_id);
};


# Compare against another field value
sub value_eq {
  my ($self, $other) = @_;
  if ($self->year == $other->year &&
        $self->month == $other->month &&
        $self->day == $other->day) {
    return 1;
  };
  return 0;
};


sub value {
  my $self = shift;
  if (@_) {
    $self->{value} = shift;
    if ($self->{value} =~ /^(\d{4})(?:-?(\d{2})(?:-?(\d{2}))?)?$/) {
      $self->{year}  = ($1 + 0) if $1;
      $self->{month} = ($2 + 0) if $2;
      $self->{day}   = ($3 + 0) if $3;
      return $self;
    };
    return;
  };
  return $self->{value};
};


sub value_string {
  my $self = shift;
  my $str = '';
  $str .= $self->year;
  if ($self->month) {
    $str .= '-' . _zero($self->month);
    if ($self->day) {
      $str .= '-' . _zero($self->day);
    };
  }
  return $str;
};

sub _zero {
  if ($_[0] < 10) {
    return '0' . $_[0]
  };
  return $_[0];
};


# Stringification for sorting
# TODO:
#   This may fail in case key_type and/or
#   value may contain ':' - so this should be
#   ensured!
sub to_sort_string {
  my $self = shift;
  return 0 if $self->is_null;

  my $str = $self->key_type . ':';
  $str .= $self->key . ':';
  $str .= ($self->value_string // '') . ':';
  $str .= $self->match_short;
  return $str;
};


1;
