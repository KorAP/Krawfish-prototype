package Krawfish::Koral::Corpus::Field::Date;
use strict;
use warnings;
use Krawfish::Util::Constants qw/:PREFIX/;
use Krawfish::Log;
use Role::Tiny::With;
use Krawfish::Koral::Corpus::DateRange;
use Krawfish::Koral::Corpus::Field::DateString;


with 'Krawfish::Koral::Util::Date';
with 'Krawfish::Koral::Corpus::Field::Relational';
with 'Krawfish::Koral::Corpus::Field';
with 'Krawfish::Koral::Corpus';

# This supports range queries on special
# date and int fields in the dictionary.

# The implementation for dates has to recognize
# that not only ranges are required to be queried, but also
# stored.

# RESTRICTION:
#   - Currently this is restricted to dates!
#   - currently this finds all intersecting dates!

# TODO:
#   Convert the strings to RFC3339, as this is a sortable
#   date format.

# TODO:
#   Support Date patterns like C2:
#   <date>m2=Year1-Year2 und Month1-Month2 </date>
#   Datumsbereich Schema 2: z.B. "1990-2000 und 06-06"
#   "Für die Auswahl von Texten, die in diesem Beispiel in den 90gern im Juni
#   erschienen sind. Anwendungen: Themen in den Sommermonaten, evtl. nur
#   Dez-Texte, etc."

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


# Convert date to query term
# This will represent an intersection
# with all dates or dateranges intersecting
# with the current date
sub to_term_query_array {
  my $self = shift;
  my $from = $self;
  my $to = shift;
  my @terms;

  # TODO:
  #   In case the term query is "strictly within",
  #   it's good to not include
  #   the "all"-queries at the start and
  #   at the end, e.g.
  #     2017-01-02--2018-04-20
  #   should not include
  #     2017], 2017-01]
  #     2018], 2018-04]
  #   In fact, these may be added in an andNot()
  #   relation instead.
  #   There may already be a normalization rule here,
  #   for (a|b|c)!&b -> (a|c)&!b

  # Match the whole granularity subtree
  # Either the day, the month or the year
  # e.g. 2015], 2015-11], 2015-11-14]
  if ($from->day) {

    # Get all day
    push @terms, $self->term_all($from->value_string(0));
  }

  elsif ($from->month) {
    # Get something in month
    push @terms, $self->term_part($from->value_string(1));
  };

  if ($from->month) {

    # Get all month
    push @terms, $self->term_all($from->value_string(1));
  }

  # Year is set
  else {

    # Get something in year
    push @terms, $self->term_part($from->value_string(2));
  };

  # Get all years
  push @terms, $self->term_all($from->value_string(2));

  return @terms unless $to;

  # There is a target date
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

    # Get all days to the end of the month
    else {

      # Retrieve all days till the end of the month
      foreach my $day ($from->day + 1 .. 31) {

        # TODO:
        #   Get all_or_part() in case dates support time
        push @terms, $self->term_all(
          $self->new_to_value_string(
            $from->year, $from->month, $day
          )
        );
      };
    };
  };


  # There was a month
  if ($from->month) {

    # year is identical
    if ($from->year == $to->year) {

      # There is a target month defined
      if ($to->month) {

        # 2005-07-14--2005-11
        # 2005-07-14--2005-11-20
        foreach my $month ($from->month + 1 .. $to->month - 1) {
          push @terms, $self->term_all_or_part(
            $self->new_to_value_string(
              $from->year, $month
            )
          );
        };

        # No day defined
        # 2005-07-14--2005-11
        unless ($to->day) {
          # Get the current month as part
          push @terms, $self->term_all_or_part(
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

      # Get anything in the manths till the end
      foreach my $month ($from->month + 1 .. 12) {
        push @terms, $self->term_all_or_part(
          $self->new_to_value_string(
            $from->year, $month
          )
        );
      };
    }
  };

  # Get anything in the years inbetween
  foreach my $year ($from->year + 1 .. $to->year - 1) {
    push @terms,
      $self->term_all_or_part(
        $self->new_to_value_string(
          $year
        )
      );
  };


  # Ends with a whole year
  unless ($to->month) {

    # Get anything in the current year
    push @terms,
      $self->term_all_or_part(
        $self->new_to_value_string(
          $to->year
        )
      );
    return @terms;
  };


  # Years differ
  if ($from->year != $to->year) {

    # Target has a month defined
    # Get all spanning years
    push @terms, $self->term_all(
      $self->new_to_value_string(
        $to->year
      )
    );

    # Get anything in the months between
    foreach my $month (1 .. $to->month - 1) {
      push @terms, $self->term_all_or_part(
        $self->new_to_value_string(
          $to->year, $month
        )
      );
    };
  };

  # No day defined
  unless ($to->day) {

    # Get all spanning month
    push @terms, $self->term_all_or_part(
      $self->new_to_value_string(
        $to->year, $to->month
      )
    );
    return @terms;
  };

  # The target has a day defined
  # Accept the whole month
  push @terms, $self->term_all(
    $self->new_to_value_string(
      $to->year, $to->month
    )
  );

  # Add all days
  foreach my $day (1 .. $to->day) {
    # TODO:
    #   Get all_or_part() in case dates support time
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
  return Krawfish::Koral::Corpus::Field::DateString->new($self->key)->all($term);
};


# Create string query for partial ranges
sub term_part {
  my ($self, $term) = @_;
  return Krawfish::Koral::Corpus::Field::DateString->new($self->key)->part($term);
};


# Create String queries for partial and all ranges
sub term_all_or_part {
  my ($self, $term) = @_;
  return (
    $self->term_all($term),
    $self->term_part($term)
  );
};


# Spawn an intersecting date range query
# TODO:
#   - rename to overlap
sub intersect {
  my $self = shift;
  my ($first, $second) = @_;

  # Make this a DateRange query
  if ($second) {
    my $cb = $self->builder;

    my $first = $cb->date($self->key)->eq($first);
    my $second = $cb->date($self->key)->eq($second);

    my ($from, $to);
    if ($first->value_lt($second)) {
      $from = $first->match('gt')->is_inclusive(1);
      $to = $second->match('lt')->is_inclusive(1);
    }
    else {
      $to = $first->match('lt')->is_inclusive(1);
      $from = $second->match('gt')->is_inclusive(1);
    };

    return Krawfish::Koral::Corpus::DateRange->new(
      $from,
      $to
    );
  };

  # Only single value available
  $self->{match} = 'intersect';
  $self->value(shift) or return;

  return $self;
};


# Normalize date
sub normalize {
  my $self = shift;

  $self->{key} = normalize_nfkc($self->key) if $self->key;

  print_log('kq_date', "Normalize " . $self->to_string) if DEBUG;

  # This should not work
  $self->{value} = normalize_nfkc($self->value) if $self->value;
  return $self;
};


# Realize query as a term query
sub to_term_query {
  my $self = shift;

  # Date is open
  if ($self->match eq 'gt') {
    return Krawfish::Koral::Corpus::DateRange->new(
      $self,
      __PACKAGE__->new($self->key)->maximum->is_inclusive(1)
    )->normalize->to_term_query;
  }

  # Date is open
  elsif ($self->match eq 'lt') {
    return Krawfish::Koral::Corpus::DateRange->new(
      __PACKAGE__->new($self->key)->minimum->is_inclusive(1),
      $self
    )->normalize->to_term_query;
  }

  # Treat query as intersection
  elsif ($self->match eq 'intersect' || $self->match eq 'eq') {
    return $self->builder->bool_or(
      $self->to_term_query_array
    )->normalize->to_term_query;
  };

  return;
};



1;
