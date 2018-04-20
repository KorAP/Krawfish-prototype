package Krawfish::Koral::Util::Date;
use Role::Tiny;
use strict;
use warnings;


# Get year value
sub year {
  $_[0]->{year};
};


# Get month value
sub month {
  $_[0]->{month} // 0;
};


# Get day value
sub day {
  $_[0]->{day} // 0;
};


# Get or set date value
sub value {
  my $self = shift;
  if (@_) {
    $self->{value} = shift;
    if ($self->{value} =~ /^\s*(\d{4})(?:\s*-\s*?(\d{2})(?:\s*-\s*?(\d{2}))?)?\s*$/) {
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


# Stringification of year, month, day
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
};


# This is duplicate in DateRange
sub _zero {
  if ($_[0] < 10) {
    return '0' . $_[0]
  };
  return $_[0];
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


# Compare against another field value
sub value_gt {
  my ($self, $other) = @_;
  if ($self->year > $other->year) {
    return 1;
  }
  elsif ($self->year < $other->year) {
    return 0;
  }
  elsif (!$self->month && !$other->month) {
    return 0; # It's equal
  }
  elsif ($self->month && !$other->month) {
    return 1;
  }
  elsif (!$self->month && $other->month) {
    return 0;
  }
  elsif ($self->month > $other->month) {
    return 1;
  }
  elsif ($self->month < $other->month) {
    return 0;
  }
  elsif (!$self->day && !$other->day) {
    return 0; # It's equal
  }
  elsif ($self->day && !$other->day) {
    return 1;
  }
  elsif (!$self->day && $other->day) {
    return 0;
  }
  elsif ($self->day > $other->day) {
    return 1;
  };
  return 0;
};


# Compare against another field value
sub value_lt {
  my ($self, $other) = @_;
  if ($self->year < $other->year) {
    return 1;
  }
  elsif ($self->year > $other->year) {
    return 0;
  }
  elsif (!$self->month && !$other->month) {
    return 0; # It's equal
  }
  elsif ($self->month && !$other->month) {
    return 0;
  }
  elsif (!$self->month && $other->month) {
    return 1;
  }
  elsif ($self->month < $other->month) {
    return 1;
  }
  elsif ($self->month > $other->month) {
    return 0;
  }
  elsif (!$self->day && !$other->day) {
    return 0; # It's equal
  }
  elsif ($self->day && !$other->day) {
    return 0;
  }
  elsif (!$self->day && $other->day) {
    return 1;
  }
  elsif ($self->day < $other->day) {
    return 1;
  };
  return 0;
};


# Check if the daterange is completely in another daterange
# or the other way around
# return
#   0:  not a part of
#   -1: other subordinates self
#   1:  self subordinates other
sub is_part_of {
  my ($self, $other) = @_;

  # No
  return if $self->year != $other->year;

  # Month not given
  if (!$self->month) {

    # 2005--2005
    # 2005--2005-10
    # 2005--2005-10-14
    return 1;
  }

  # No other month
  elsif (!$other->month) {

    # 2005-10--2005
    # 2005-10-14--2005
    return -1;
  };

  # No
  return if $self->month != $other->month;

  # Day is not given
  if (!$self->day) {
    # 2005-10--2005-10
    # 2005-10--2005-10-14
    return 1;
  }

  # No other day
  elsif (!$other->day) {
    # 2005-10-14--2005-10
    return -1;
  };

  # No
  return if $self->day != $other->day;

  # Dates are equal
  return 1;
};


# Normalize implicite range
# 2007-01-01--2008-12-31
# -> 2007-2008
sub normalize_range_calendaric {
  my ($self, $other) = @_;

  # Either in different year or in different month
  if ($self->year != $other->year ||
        $self->month != $other->month) {

    # First month is completely covered
    if ($self->day == 1) {
      $self->{day} = 0;
    };

    # Last Month is completely covered
    if ($other->is_last_day_of_month) {
      $other->{day} = 0;
    };
  }

  # In same year and same month
  elsif ($self->year == $other->year) {
    if ($self->month == $other->month) {
      if ($self->day == 1 && $other->is_last_day_of_month) {
        $self->{day} = 0;
        $other->{day} = 0;
      };
    };
  };


  if ($self->year != $other->year) {

    # 2007-01--2008-02
    if (!$self->day && $self->month == 1) {
      $self->{month} = 0;
    };

    # 2007-05--2008-12
    if (!$other->day && $other->month == 12) {
      $other->{month} = 0;
    };
  }

  # Year is the same
  elsif (!$self->day &&
           !$other->day &&
           $self->month == 1 &&
           $other->month == 12) {
    $self->{month} = 0;
    $other->{month} = 0;
  };

  return 1;
};


# Check if the given day is the last day of the month
sub is_last_day_of_month {
  my $self = shift;

  if ($self->day == 31) {
    return 1;
  }

  # Month has 30 days
  if ($self->day == 30 && (
    $self->month == 2 ||
      $self->month == 4 ||
      $self->month == 6 ||
      $self->month == 9 ||
      $self->month == 11)
    ) {
    return 1;
  };

  # Nonth has 29 days max
  if ($self->day == 29 &&
        $self->month == 2) {
    return 1;
  };

  return 0;
};


1;
