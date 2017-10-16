package Krawfish::Koral::Document::FieldStore;
use Krawfish::Util::String qw/squote/;
use Krawfish::Util::Constants ':PREFIX';
use Role::Tiny::With;
with 'Krawfish::Koral::Document::FieldBase';
use warnings;
use strict;

# Class for store-only fields
# (not indexed in the dictionary)


sub type {
  'store'
};

# There is no term_id, but it's required for sorting
sub term_id { undef };


sub identify {
  my ($self, $dict) = @_;

  my $key  = KEY_PREF . $self->{key};

  # Get or introduce new key term_id
  $self->{key_id} = $dict->add_term($key);

  return $self;
};


# Inflate field
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


sub to_string {
  my $self = shift;
  my $str = $self->key_id ? '#' . $self->key_id : squote($self->key);
  return $str . '=' . squote($self->value);
};

sub sortable { 0 }

1;
