package Krawfish::Koral::Document::Field::Date;
use strict;
use warnings;
use Role::Tiny;

sub year {
  $_[0]->{year};
};

sub month {
  $_[0]->{month} // 0;
};

sub day {
  $_[0]->{day} // 0;
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


# Serialize the value string
# Accepts an optional granularity value
# with: 0 = all
#       1 = till month
#       2 = till year
sub value_string {
  my ($self, $granularity) = @_;
  $granularity //= 0;

  if ($granularity == 0) {
    return $self->new_to_value_string($self->year, $self->month, $self->day);
  }

  elsif ($granularity == 1) {
    return $self->new_to_value_string($self->year, $self->month);
  };

  return $self->new_to_value_string($self->year);
};


sub new_to_value_string {
  my ($self, $year, $month, $day) = @_;
  my $str = '';
  $str .= $year;
  if ($month) {
    $str .= '-' . _zero($month);
    if ($day) {
      $str .= '-' . _zero($day);
    };
  };
  return $str;
}


# This is duplicate in DateRange
sub _zero {
  if ($_[0] < 10) {
    return '0' . $_[0]
  };
  return $_[0];
};


1;
