package Krawfish::Koral::Document::FieldString;
use Krawfish::Util::String qw/squote/;
use Krawfish::Util::Constants ':PREFIX';
use Role::Tiny::With;
with 'Krawfish::Koral::Document::FieldBase';
use warnings;
use strict;

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


# Inflate key
sub inflate {
  my ($self, $dict) = @_;

  # Key id not available
  return unless $self->{key_value_id};

  # Get term from term id
  my $field = $dict->term_by_term_id($self->{key_value_id});

  my $field_pref = quotemeta(FIELD_PREF);
  if ($field =~ /^$field_pref([^:]+):(.+)$/) {
    $self->{key} = $1;
    $self->{value} = $2;
  }
  else {
    warn 'Field has no valid attribute';
  };

  return $self;
};

# Stringification
sub to_string {
  my $self = shift;
  unless ($self->{key_id}) {
    return squote($self->key) . '=' . squote($self->value);
  };
  return '#' . $self->key_id . '=' . '#' . $self->term_id;
};

1;
