package Krawfish::Koral::Corpus::DateRange;
use Role::Tiny::With;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

with 'Krawfish::Koral::Corpus';

# The implementation for dates has to recognize
# that not only ranges are required to be queried, but also
# stored.

# RESTRICTION:
#   - Currently this is restricted to dates!
#   - currently this finds all intersecting dates only!


# TODO:
#   In https://home.apache.org/~hossman/spatial-for-non-spatial-meetup-20130117/ there is support for
#   - doc duration intersects with query duration
#   - doc duration overlaps with query duration
#   - doc duration is within with query duration


sub type {
  'date_range'
};


# Constructor
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

  print_log('kq_daterange', 'Normalize DateRange ' . $self->to_string) if DEBUG;

  my @terms;

  my ($from, $to) = ($self->{first}, $self->{second});

  # Respect inclusivity/exclusivity
  unless ($from->is_inclusive) {
    $from = $from->next_date->is_inclusive(1);
    $self->{first} = $from;
  };

  unless ($to->is_inclusive) {
    $to = $to->previous_date->is_inclusive(1);
    $self->{second} = $to;
  };

  # The daterange may be negative
  my $neg = $self->is_negative;

  # There is a range target
  if ($to) {
    $from->normalize_range_calendaric(
      $to
    );

    if (my $part_of = $from->is_part_of($to)) {

      if (DEBUG) {
        print_log(
          'kq_daterange',
          "Normalize daterange with part of=$part_of"
        );
      };

      # From subordinates to - to is irrelevant
      # 2005-10--2005-10-14
      if ($part_of == 1) {

        # TODO: RESPECT NEGATIVITY
        return $from->match('intersect')->normalize;
      }

      # To subordinates from - from is irrelevant
      # 2005-10-01--2005-10
      elsif ($part_of == -1) {
        # $from = $to;
        # $to = undef;
        return $to->match('intersect')->normalize;
      };
    };
  };

  $self->{first} = $from;
  $self->{second} = $to;

  return $self;
};


# Realize term queries
# TODO:
#   terminologcally this may be renamed to_term_queries
#   and change meanings.
sub realize {
  my $self = shift;

  # The daterange may be negative
  my $neg = $self->is_negative;

  my $group = $self->builder->bool_or(
    $self->to_term_queries
  );

  if ($neg) {
    $group->is_negative(1);
  };

  return $group->normalize->realize;
};


# Return all terms intersecting the range
# TODO:
#   Rename to overlap?
sub to_term_queries {
  my $self = shift;

  # TODO:
  #   First order!

  my ($from, $to) = ($self->{first}, $self->{second});

  # Respect inclusivity/exclusivity
  unless ($from->is_inclusive) {
    $from = $from->next_date->is_inclusive(1);
    $self->{first} = $from;
  };

  unless ($to->is_inclusive) {
    $to = $to->previous_date->is_inclusive(1);
    $self->{second} = $to;
  };

  return $from->to_term_queries(
    $to
  );
};


# stringify range query
sub to_string {
  my $self = shift;

  return 0 if $self->is_null;

  my $str = '';

  $str .= $self->{first}->key;

  $str .= '&';
  if ($self->is_negative) {
    $str .= '!';
  };
  $str .= '=';

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
