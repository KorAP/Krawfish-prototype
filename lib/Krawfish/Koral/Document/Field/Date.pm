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
  my $to = shift;
  my @terms;


  # TODO:
  #   Normalize
  #   2005-09-05--2005-09 -> 2005-09
  #   2005-09-05--2005 -> 2005

  # TODO:
  #   Respect inclusivity

  # There is a single value in the day
  if ($self->day) {
    push @terms, $self->term_all($self->value_string(0));
    push @terms, $self->term_part($self->value_string(1));
    push @terms, $self->term_part($self->value_string(2));
  }

  # There is a single value in the month
  elsif ($self->month) {
    push @terms, $self->term_all($self->value_string(1));
    push @terms, $self->term_part($self->value_string(2));
  }

  # There is a single value in the year
  else {
    push @terms, $self->term_all($self->value_string(2));
  };

  # There is a target date
  if ($to) {

    # There was a day restriction
    if ($self->day) {

      # year and month are identical
      if ($self->year == $to->year &&
            $self->month == $to->month &&
            $to->day) {

        # 2005-10-14--2005-10-20
        foreach my $day ($self->day + 1 .. $to->day) {
          push @terms, $self->term_all(
            $self->new_to_value_string(
              $self->year, $self->month, $day
            )
          );
        };
        return @terms;
      }

      # get all days to the end of the month
      else {

        # 2005-10-14--2005-10-20
        foreach my $day ($self->day + 1 .. 31) {
          push @terms, $self->term_all(
            $self->new_to_value_string(
              $self->year, $self->month, $day
            )
          );
        };
      };
    };

    # There was a month restriction
    if ($self->month) {

      # year is identical
      if ($self->year == $to->year &&
            $to->month) {

        # 2005-07-14--2005-11-20
        foreach my $month ($self->month + 1 .. $to->month - 1) {
          push @terms, $self->term_all(
            $self->new_to_value_string(
              $self->year, $month
            )
          );
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
      };
    };
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
