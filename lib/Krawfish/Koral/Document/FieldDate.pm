package Krawfish::Koral::Document::FieldDate;
use warnings;
use strict;
use Krawfish::Util::String qw/squote/;
use Krawfish::Util::Constants qw/:PREFIX :RANGE/;
use Role::Tiny::With;
use Krawfish::Log;

with 'Krawfish::Koral::Document::Field::Date';
with 'Krawfish::Koral::Document::FieldBase';

use constant DEBUG => 0;

# Class for date fields

# TODO:
#   Move parts of it to Koral::Document::Field::Date!

# TODO:
#   Support DateRange fields as well!

# TODO:
#   Join this with
#   Krawfish::Koral::Corpus::Field::Date

# TODO:
#   Support date ranges!

sub type {
  'date';
};


sub new {
  my $class = shift;
  # key, value, key_id, key_value_id, sortable
  my $self = bless {
    @_
  }, $class;

  # Parse value!
  $self->value($self->{value});
  # + year, month, day

  return $self;
};


# Get all range term identifier
sub range_term_ids {
  return $_[0]->{range_term_ids};
};



sub identify {
  my ($self, $dict) = @_;

  # This will check, if the field is
  # sortable
  return $self if $self->{key_id} && $self->{key_value_id};

  # Get or introduce new key term_id
  my $key = KEY_PREF . $self->{key};

  # THIS WILL STORE THE INFLATABLE STRING
  # (may not be necessary)
  $self->{key_id} = $dict->add_term($key);

  if (DEBUG) {
    print_log('k_doc_fdate', 'Check for sortability for ' . $self->{key_id});
  };

  # Set sortable
  if (my $collation = $dict->collation($self->{key_id})) {
    if (DEBUG) {
      print_log('k_doc_fdate', 'Field ' . $self->{key_id} . ' is sortable');
    };
    $self->{sortable} = 1;
  };

  # Get or introduce new key term_id
  my $term = DATE_FIELD_PREF . $self->{key} . ':' . $self->{value};
  $self->{key_value_id} = $dict->add_term($term);

  # Index more terms for range queries
  $self->{range_term_ids} = [];
  foreach ($self->to_range_terms) {
    push @{$self->{range_term_ids}}, $dict->add_term($_);
  };

  return $self;
};


# Inflate field
# The date is stored uncompressed
sub inflate {
  my ($self, $dict) = @_;

  # TODO:
  #   It may not be useful to
  #   provide this information
  #   As the correct stored value is probably
  #   only retrievable from the forward index.

  # Key id not available
  return unless $self->{key_id};

  # Get term from term id
  $self->{key} = substr(
    $dict->term_by_term_id($self->{key_id}),
    1
  );

  return $self;
};


# Stringification
sub to_string {
  my ($self, $id) = @_;

  if (!$self->{key} || ($id && $self->{key_id})) {
    return '#' . $self->key_id . '=' . '#' .  $self->{key_value_id} . '(' . $self->{value} . ')';
  };
  return squote($self->key) . '=' . $self->value;
};


# Create all terms relevant for the index
# TODO:
#   Currently limited to single date strings
sub to_range_terms {
  my $self = shift;
  my @terms;

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


1;
