package Krawfish::Koral::Document::Field::String;
use warnings;
use strict;
use Krawfish::Util::String qw/squote/;
use Krawfish::Util::Constants ':PREFIX';
use Role::Tiny::With;

with 'Krawfish::Koral::Document::Field';

# Class for string fields


sub type {
  'string';
};


sub identify {
  my ($self, $dict) = @_;

  # This will check, if the field is
  # sortable
  return $self if $self->{key_id} && $self->{key_value_id};

  # Get or introduce new key term_id
  my $key = KEY_PREF . $self->{key};

  $self->{key_id} = $dict->add_term($key);

  # Set sortable
  if (my $collation = $dict->collation($self->{key_id})) {
    $self->{sortable} = 1;
  };

  # Get or introduce new key term_id
  my $term = FIELD_PREF . $self->{key} . ':' . $self->{value};
  $self->{key_value_id} = $dict->add_term($term);

  return $self;
};


# Inflate field
sub inflate {
  my ($self, $dict) = @_;

  # Key id not available
  return unless $self->{key_value_id};

  # Get term from term id
  my $field = $dict->term_by_term_id($self->{key_value_id});

  if ($field =~ /^([^:]+):(.+)$/) {
    $self->{key} = substr($1, 1); # Remove prefix
    $self->{value} = $2;
  }
  else {
    warn 'Field has no valid attribute';
  };

  return $self;
};


# Stringification
sub to_string {
  my ($self, $id) = @_;

  if (!$self->{key} || ($id && $self->{key_id})) {
    return '#' . $self->key_id . '=' . '#' . $self->term_id;
  };
  return squote($self->key) . '=' . squote($self->value);
};

1;
