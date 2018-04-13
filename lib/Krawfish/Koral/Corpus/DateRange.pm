package Krawfish::Koral::Corpus::DateRange;
use Role::Tiny::With;
use strict;
use warnings;

with 'Krawfish::Koral::Corpus';

# The implementation for dates has to recognize
# that not only ranges are required to be queried, but also
# stored.

# RESTRICTION:
#   - Currently this is restricted to dates!
#   - currently this finds all intersecting dates!


# TODO:
#   In https://home.apache.org/~hossman/spatial-for-non-spatial-meetup-20130117/ there is support for
#   - doc duration intersects with query duration
#   - doc duration overlaps with query duration
#   - doc duration is within with query duration


sub type {
  'dateRange'
};

sub new {
  my $class = shift;

  my ($first, $second) = @_;

  if ($first->key ne $second->key ||
        $first->key_type ne $second->key_type ||
        $first->key_type ne 'date'
      ) {
    warn $first->to_string . ' and ' . $second->to_string . ' are incompatible for daterange';
    # TODO: Add error to report type!
  };

  return bless {
    first => $first,
    second => $second,
  }, $class;
};

# Turn the date range query into an or-query
sub normalize {
  my $self = shift;

  my @terms;
  if ($self->{first}) {
    push @terms, $self->{first}->to_query_terms;
  };

  # TODO:
  #   Return or-query
  return $self;
};


# Return all terms intersecting the range
# TODO:
#   Rename to overlap?
sub to_intersecting_terms {
  my $self = shift;

  # TODO:
  #   First order!

  my ($first, $second) = ($self->{first}, $self->{second});

  # TODO:
  #   Treat inclusive terms different to
  #   exclusive terms!

  my @terms = $first->to_intersecting_terms;

  if ($second) {
    push @terms, $second->to_intersecting_terms;
  };

  my $cb = $self->builder;

  # Add all years between the years
  if ($first->year < $second->year) {
    foreach my $year (($first->year + 1) .. $second->year - 1) {

      my $year_str = $first->new_to_value_string($year);
      push @terms, $first->term_part($year_str);
      push @terms, $first->term_all($year_str);
    };
  }

  # Years are identical
  else {
    # Iterate over months in between
    ...
  };

  return sort {
    $a->to_sort_string cmp $b->to_sort_string
  } @terms;

  # Accept all months following the first date
  # (excluding the first)
  if ($first->month && $first->month < 12) {
    foreach my $month ($first->month + 1 .. 12) {
      push @terms, $first->term_all($month);
    };
  };

  # Accept all days following the first date
  # (excluding the first)
  # TODO:
  #   It may be beneficial to have shortcuts
  #   0 <= 15 && 16 <= 31!
  if ($first->day && $first->day < 31) {
    foreach my $day (($first->day + 1) .. 31) {
      push @terms, $first->term_all($day);
    };
  };

  # Accept all months preceding the second date
  # (excluding the second date)
  if ($second->month) {
    foreach my $month (1 .. $second->month + 1) {
      push @terms,
        $first->term_all(_zero($first->year) . '-' . $month);
    };
  };

  return @terms;
};


# stringify range query
sub to_string {
  my $self = shift;

  return 0 if $self->is_null;

  my $str = '';
  $str .= $self->{first}->key;

  $str .= '&=';

  $str .= '[';

  my ($first, $second) = ($self->{first}, $self->{second});

  if ($first->is_inclusive) {
    $str .= '[' . $first->value_string;
  }
  else {
    $str .= $first->value_string . '[';
  };

  $str .= '--';

  if ($second) {

    if ($second->is_inclusive) {
      $str .= $second->value_string . ']';
    }
    else {
      $str .= ']' . $second->value_string;
    };
  };
  return $str . ']';
};


sub from_koral { ... };

sub to_koral_fragment { ... };

sub optimize { ... };


1;
