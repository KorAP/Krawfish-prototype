package Krawfish::Koral::Document::Field::Date;
use strict;
use warnings;
use Krawfish::Util::String qw/squote/;
use Krawfish::Util::Constants qw/:PREFIX :RANGE/;
use Role::Tiny::With;

# TODO:
#   Make this a separate class to be used by daterange!
# with 'Krawfish::Koral::Document::FieldBase';
with 'Krawfish::Koral::Util::Date';

sub new {
  my $class = shift;
  my $self = bless {
    @_
  }, $class;

  unless ($self->value($self->{value})) {
    return;
  };

  return $self;
};


# Create all terms relevant for the index
# TODO:
#   Currently limited to single date strings
sub to_range_terms {
  my $self = shift;
  my $from = $self;
  my $to = shift;
  my @terms;

  # TODO:
  #   Respect inclusivity

  # TODO:
  #   Normalize
  #   2005-01--2006-12 -> 2005--2006

  # There is a target
  if ($to) {

    # Check if one range subordinates the other
    if (my $part_of = $from->is_part_of($to)) {

      # From subordinates to - to is irrelevant
      if ($part_of == 1) {
        $to = undef;
      }

      # To subordinates from - from is irrelevant
      elsif ($part_of == -1) {
        $from = $to;
        $to = undef;
      };
    };
  };

  # There is a single value in the day
  if ($from->day) {
    push @terms, $self->term_all($from->value_string(0));
    push @terms, $self->term_part($from->value_string(1));
    push @terms, $self->term_part($from->value_string(2));
  }

  # There is a single value in the month
  elsif ($from->month) {
    push @terms, $self->term_all($from->value_string(1));
    push @terms, $self->term_part($from->value_string(2));
  }

  # There is a single value in the year
  else {
    push @terms, $self->term_all($from->value_string(2));
  };

  # There is no target date
  return @terms unless $to;

  # There is a target date
  # There was a day restriction
  if ($from->day) {

    # year and month are identical
    if ($from->year == $to->year &&
          $from->month == $to->month &&
          $to->day) {

      # 2005-10-14--2005-10-20
      foreach my $day ($from->day + 1 .. $to->day) {
        push @terms, $self->term_all(
          $self->new_to_value_string(
            $from->year, $from->month, $day
          )
        );
      };
      return @terms;
    }

    # Store all days to the end of the month
    else {

      # 2005-10-14--
      foreach my $day ($from->day + 1 .. 31) {
        push @terms, $self->term_all(
          $self->new_to_value_string(
            $from->year, $from->month, $day
          )
        );
      };
    };
  };

  # At this point, we have the days summed up for the from-month

  # There was a month restriction
  if ($from->month) {

    # year is identical
    if ($from->year == $to->year) {

      # There is a target month defined
      if ($to->month) {

        # 2005-07-14--2005-11
        # 2005-07-14--2005-11-20
        foreach my $month ($from->month + 1 .. $to->month - 1) {
          push @terms, $self->term_all(
            $self->new_to_value_string(
              $from->year, $month
            )
          );
        };

        # No day defined
        # 2005-07-14--2005-11
        unless ($to->day) {
          # Store the current month as all
          push @terms, $self->term_all(
            $self->new_to_value_string(
              $to->year, $to->month
            )
          );
          return @terms;
        };

        # 2005-07-14--2005-11-20
      }
    }

    # Years are different - so months need to add up
    else {

      # Add month till the end of year
      foreach my $month ($from->month + 1 .. 12) {
        push @terms, $self->term_all(
          $self->new_to_value_string(
            $from->year, $month
          )
        );
      };
    };
  };

  # Add years inbetween
  foreach my $year ($from->year + 1 .. $to->year - 1) {
    push @terms, $self->term_all(
      $self->new_to_value_string(
        $year
      )
    );
  };

  # No month defined
  # 2005--2006
  # 2005-07--2006
  # 2005-07-14--2006
  unless ($to->month) {
    # Store the current year as all
    push @terms, $self->term_all(
      $self->new_to_value_string(
        $to->year
      )
    );
    return @terms;
  }

  # Years differ
  if ($from->year != $to->year) {

    # The target has a month defined
    # 2005--2006-04
    # 2005-07--2006-04
    # 2005-07-14--2006-04
    # Store the current year as partial
    push @terms, $self->term_part(
      $self->new_to_value_string(
        $to->year
      )
    );

    # Add all months
    foreach my $month (1 .. $to->month - 1) {
      push @terms, $self->term_all(
        $self->new_to_value_string(
          $to->year, $month
        )
      );
    };
  };

  # No day defined
  unless ($to->day) {

    # Store the current month as all
    push @terms, $self->term_all(
      $self->new_to_value_string(
        $to->year, $to->month
      )
    );
    return @terms;
  };

  # The target has a day defined
  # 2005--2006-04-02
  # 2005-07--2006-04-02
  # 2005-07-14--2006-04-02
  # Store the current month as partial
  push @terms, $self->term_part(
    $self->new_to_value_string(
      $to->year, $to->month
    )
  );

  # Add all days
  foreach my $day (1 .. $to->day) {
    push @terms, $self->term_all(
      $self->new_to_value_string(
        $to->year, $to->month, $day
      )
    );
  };

  return @terms;
};


# Create string query for all ranges
sub term_all {
  my ($self, $term) = @_;
  return DATE_FIELD_PREF . $self->{key} . ':' . $term . RANGE_ALL_POST
};


# Create string query for partial ranges
sub term_part {
  my ($self, $term) = @_;
  return DATE_FIELD_PREF . $self->{key} . ':' . $term . RANGE_PART_POST
};


# Stringification
#   Identical to FieldDate (DateRange)
sub to_string {
  my ($self, $id) = @_;

  if (!$self->{key} || ($id && $self->{key_id})) {
    return '#' . $self->key_id . '=' . '#' .  $self->{key_value_id} . '(' . $self->{value} . ')';
  };
  return squote($self->key) . '=' . $self->value;
};

1;
