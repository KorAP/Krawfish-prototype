package Krawfish::Koral::Document::FieldDate;
use warnings;
use strict;
use Krawfish::Util::String qw/squote/;
use Krawfish::Util::Constants ':PREFIX';
use Role::Tiny::With;
use Krawfish::Log;

with 'Krawfish::Koral::Document::FieldBase';

use constant DEBUG => 0;

# Class for date fields

# TODO:
#   Potentially join with
#   Krawfish::Koral::Corpus::Field::Date

sub type {
  'date';
};


sub identify {
  my ($self, $dict) = @_;

  # This will check, if the field is
  # sortable
  return $self if $self->{key_id} && $self->{key_value_id};

  # Get or introduce new key term_id
  my $key = KEY_PREF . $self->{key};

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

  return $self;
};


# Inflate field
# The date is stored uncompressed
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
sub to_string {
  my ($self, $id) = @_;

  if (!$self->{key} || ($id && $self->{key_id})) {
    return '#' . $self->key_id . '=' . '#' .  $self->{key_value_id} . '(' . $self->{value} . ')';
  };
  return squote($self->key) . '=' . $self->value;
};

1;
