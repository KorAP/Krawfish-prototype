package Krawfish::Koral::Corpus::DateRange;
use Role::Tiny::With;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 1;

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

  my @terms;

  my ($from, $to) = ($self->{first}, $self->{second});

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
        return $from->match('eq')->normalize;
      }

      # To subordinates from - from is irrelevant
      # 2005-10-01--2005-10
      elsif ($part_of == -1) {
        # $from = $to;
        # $to = undef;
        return $to->match('eq')->normalize;
      };
    };
  };

  $self->{first} = $from;
  $self->{second} = $to;

  return $self->builder->bool_or(
    $self->to_term_queries
  )->normalize;
};


# Return all terms intersecting the range
# TODO:
#   Rename to overlap?
sub to_term_queries {
  my $self = shift;

  # TODO:
  #   First order!

  my ($first, $second) = ($self->{first}, $self->{second});

  # TODO:
  #   Treat inclusive terms different to
  #   exclusive terms!

  return $first->to_term_queries(
    $second
  );
};


# Only for testing:
# Serialization of all range terms
#sub to_range_term_string {
#  my $self = shift;
#  my @terms = sort {
#    $a->to_sort_string cmp $b->to_sort_string
#  } $self->to_term_queries;
#  return join(',', map { $_->to_string } @terms);
#};


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
