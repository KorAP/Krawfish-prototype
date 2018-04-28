package Krawfish::Koral::Corpus::Field::DateString;
use Krawfish::Util::String qw/normalize_nfkc/;
use Krawfish::Util::Constants qw/:PREFIX :RANGE/;
use Role::Tiny::With;
use strict;
use warnings;

with 'Krawfish::Koral::Util::Date';
with 'Krawfish::Koral::Corpus::Field';
with 'Krawfish::Koral::Corpus';

use constant DEBUG => 0;

sub new {
  my $class = shift;
  bless {
    key => shift,
    match => 'eq'
  }, $class;
};


sub key_type {
  'date_string';
};


# Define term as partial
sub part {
  my $self = shift;
  $self->value(shift) or return;
  $self->{range} = RANGE_PART_POST;
  return $self;
};


# Define term as all
sub all {
  my $self = shift;
  $self->value(shift) or return;
  $self->{range} = RANGE_ALL_POST;
  return $self;
};


# Translate all terms to term ids
sub identify {
  my ($self, $dict) = @_;

  my $term = $self->to_term;

  print_log('kq_term', "Translate term $term to term_id") if DEBUG;

  my $term_id = $dict->term_id_by_term(FIELD_PREF . $term);

  return $self->builder->nowhere unless defined $term_id;

  return Krawfish::Koral::Corpus::FieldID->new($term_id);
};


# The valuestring has the range marker attached
sub value_string {
  return $_[0]->{value} . $_[0]->{range};
};


# Compare against another field value
sub value_eq {
  my ($self, $other) = @_;
  if ($self->value eq $other->value) {
    return 1;
  };
  return 0;
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
  $str .= ($self->value_string // '');
  return $str;
};


# Identical to String
sub normalize {
  my $self = shift;
  $self->{value} = normalize_nfkc($self->value) if $self->value;
  $self->{key} = normalize_nfkc($self->key) if $self->key;
  return $self;
};

sub range {
  $_[0]->{range};
};


sub is_relational {
  0;
};

# Check if the daterange to query is completely in another daterange
# or the other way around
# return
#   0:  not a part of
#   -1: other subordinates self
#   1:  self subordinates other
# 2005[ and 2005-11...
sub is_part_of {
  my ($self, $other) = @_;

  # No
  return 0 if $self->year != $other->year;

  # self: 2014[ | 2014-10[
  # other: 2014[ | 2014] | 2014-10[ | 2014-10] | 2014-10-12]
  if ($self->range eq RANGE_PART_POST) {

    # self: 2014[
    unless ($self->month) {

      # other: 2014]
      return 0 unless $other->month;

      # other: 2014-x
      return 1;
    };

    # self: 2014-10[
    # other: 2014[ | 2014-10[ | 2014-11[
    if ($other->range eq RANGE_PART_POST) {

      # self: 2014-10[
      # other: 2014[
      return -1 unless $other->month;

      # self: 2014-10[
      # other: 2014-11[
      return 0 if $self->month != $other->month;

      # self: 2014-10[
      # other: 2014-10[
      return 1;
    };

    # self: 2014-10[
    # other: 2014-10-12]
    if ($other->day) {
      return 1 if $self->month == $other->month;
    };

    # self: 2014-10[
    # other: 2014] | 2014-10] | 2014-11] | 2014-11-12]
    return 0;
  }

  # self: 2014] | 2014-10] | 2014-10-12] | 2014-11] | 2014-11-12]
  # other: 2014[ | 2014-10[ | 2014-11[
  elsif ($other->range eq RANGE_PART_POST) {

    # self: 2014] | 2014-10] | 2014-11
    # other: 2014[
    unless ($other->month) {

      # self: 2014]
      # other: 2014[
      return 0 unless $self->month;

      # self: 2014-x
      return -1;
    };

    # self: 2014-10-12]
    # other: 2014-10[
    if ($self->day) {
      return -1 if $self->month == $other->month;
    };

    # self: 2014] | 2014-10] | 2014-11] | 2014-11-12]
    # other: 2014-10[
    return 0;
  };

  # self: 2014] | 2014-10] | 2014-10-12]
  # other: 2014] | 2014-10] | 2014-11] | 2014-10-12] | 2014-11-12]
  return 0;
};

1;
