package Krawfish::Koral::Corpus::Field::Date;
use Role::Tiny::With;
use strict;
use warnings;

with 'Krawfish::Koral::Corpus::Field';
with 'Krawfish::Koral::Corpus::Field::Relational';
with 'Krawfish::Koral::Corpus';

use constant DEBUG => 0;

# TODO: A date should probably have a different prefix

# TODO:
#   Compare with de.ids_mannheim.korap.util.KrillDate

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
  $_[0]->_parse->{year} + 0;
};

sub month {
  ($_[0]->_parse->{month} // 0) + 0;
};

sub day {
  ($_[0]->_parse->{day} // 0) + 0;
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


sub _parse {
  my $self = shift;
  return $self if $self->{year};
  $self->{value} =~ /^(\d{4})(?:-?(\d{2})(?:-?(\d{2}))?)?$/;
  $self->{year}  = $1;
  $self->{month} = $2 if $2;
  $self->{day}   = $3 if $3;
  return $self;
};

sub value_string {
  my $self = shift;
  my $str = $self->year;
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


1;
