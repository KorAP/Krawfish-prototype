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
  my @terms;

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
