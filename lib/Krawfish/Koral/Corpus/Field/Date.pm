package Krawfish::Koral::Corpus::Field::Date;
use strict;
use warnings;
use Krawfish::Util::Constants qw/:PREFIX :RANGE/;
use Krawfish::Log;
use Krawfish::Koral::Corpus::DateRange;
use Role::Tiny::With;


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
sub to_term_queries {
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

  # Normalize
  # if ($to) {
  # }

  # Match the whole granularity subtree
  # Either the day, the month or the year
  # e.g. 2015], 2015-11], 2015-11-14]
  if ($self->day) {

    # Get all day
    push @terms, $self->term_all($self->value_string(0));
  }

  elsif ($self->month) {
    # Get something in month
    push @terms, $self->term_part($self->value_string(1));
  };

  if ($self->month) {

    # Get all month
    push @terms, $self->term_all($self->value_string(1));
  }

  # Year is set
  else {

    # Get something in year
    push @terms, $self->term_part($self->value_string(2));
  };

  # Get all years
  push @terms, $self->term_all($self->value_string(2));

  return @terms unless $to;

  if ($from->day) {
    # ...
  };

  if ($from->month) {
    # ...
  };

  # Add years inbetween
  foreach my $year ($from->year + 1 .. $to->year - 1) {
    push @terms,
      $self->term_part(
        $self->new_to_value_string(
          $year
        )
      ),
      $self->term_all(
        $self->new_to_value_string(
          $year
        )
      );
  };


  unless ($to->month) {
    # Store the current year as all
    push @terms,
      $self->term_part(
        $self->new_to_value_string(
          $to->year
        )
      ),
      $self->term_all(
        $self->new_to_value_string(
          $to->year
        )
      );
    return @terms;
  };

  # ...
  return @terms;
};


# Create string query for all ranges
sub term_all {
  my ($self, $term) = @_;
  return $self->builder->string($self->key)->eq(
    $term . RANGE_ALL_POST
  );
};


# Create string query for partial ranges
sub term_part {
  my ($self, $term) = @_;
  return $self->builder->string($self->key)->eq(
    $term . RANGE_PART_POST
  );
};


# Spawn an intersecting date range query
# TODO:
#   - rename to overlap
#   - This treats all terms inclusive
sub intersect {
  my $self = shift;
  my ($first, $second) = @_;

  # Make this a DateRange query
  if ($second) {
    my $cb = $self->builder;

    return Krawfish::Koral::Corpus::DateRange->new(
      $cb->date($self->key)->geq($first),
      $cb->date($self->key)->leq($second)
    );
  };

  $self->{match} = 'intersect';
  $self->value(shift) or return;

  return $self;
};




1;