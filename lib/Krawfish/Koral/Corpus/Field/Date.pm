package Krawfish::Koral::Corpus::Field::Date;
use strict;
use warnings;
use Krawfish::Util::Constants qw/:PREFIX :RANGE/;
use Krawfish::Log;
use Krawfish::Koral::Corpus::DateRange;
use Role::Tiny::With;

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

sub year {
  $_[0]->{year};
};

sub month {
  $_[0]->{month} // 0;
};

sub day {
  $_[0]->{day} // 0;
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
  my $str = '';
  $str .= $self->year;
  if ($self->month && $granularity <= 1) {
    $str .= '-' . _zero($self->month);
    if ($self->day && $granularity <= 0) {
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
sub to_intersecting_terms {
  my $self = shift;
  my @terms;

  # Match the whole granularity subtree
  # Either the day, the month or the year
  # e.g. 2015], 2015-11], 2015-11-14]
  if ($self->day) {
    push @terms, $self->term_all($self->value_string(0));
  }
  elsif ($self->month) {
    push @terms, $self->term_part($self->value_string(1));
  };

  if ($self->month) {
    push @terms, $self->term_all($self->value_string(1));
  }
  else {
    push @terms, $self->term_part($self->value_string(2));
  };

  push @terms, $self->term_all($self->value_string(2));

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
