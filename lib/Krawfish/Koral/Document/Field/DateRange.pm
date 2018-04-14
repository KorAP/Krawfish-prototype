package Krawfish::Koral::Document::Field::DateRange;
use strict;
use warnings;
use Role::Tiny::With;
use Krawfish::Util::String qw/squote/;
use Krawfish::Util::Constants qw/:PREFIX :RANGE/;
use Krawfish::Koral::Document::FieldDate;
use Krawfish::Log;

with 'Krawfish::Koral::Document::FieldBase';

use constant DEBUG => 0;

sub new {
  my $class = shift;

  my $self = bless { @_ }, $class;

  $self->{value} = $self->from->value_string . RANGE_SEP . $self->to->value_string;

  return $self;
};


sub type {
  'dateRange'
};

sub from {
  $_[0]->{from};
};


sub to {
  $_[0]->{to};
};

sub to_koral_fragment {
  my $self = shift;

  unless ($self->key) {
    warn 'Inflate!';
    return;
  };

  return {
    '@type' => 'koral:field',
    'type' => 'type:date',
    'from' => $self->from->value_string,
    'to' => $self->to->value_string,
    'key' => $self->key
  };
};


# TODO:
#   This is identical to FieldDate!
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
    print_log('k_doc_fdaterange', 'Check for sortability for ' . $self->{key_id});
  };

  # Set sortable
  if (my $collation = $dict->collation($self->{key_id})) {
    if (DEBUG) {
      print_log('k_doc_fdaterange', 'Field ' . $self->{key_id} . ' is sortable');
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


# Get all range term identifier
# TODO:
#   Identical to FieldDate
sub range_term_ids {
  return $_[0]->{range_term_ids};
};



# Inflate field
# The date range is stored uncompressed
# TODO:
#   Identical to FieldDate!
sub inflate {
  my ($self, $dict) = @_;

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
# TODO:
#   Identical to FieldDate
sub to_string {
  my ($self, $id) = @_;

  if (!$self->{key} || ($id && $self->{key_id})) {
    return '#' . $self->key_id . '=' . '#' .  $self->{key_value_id} . '(' . $self->{value} . ')';
  };
  return squote($self->key) . '=' . $self->value;
};


1;
