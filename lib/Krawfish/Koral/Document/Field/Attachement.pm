package Krawfish::Koral::Document::Field::Attachement;
use warnings;
use strict;
use Krawfish::Util::String qw/squote aquote/;
use Krawfish::Util::Constants ':PREFIX';
use Role::Tiny::With;

# Class for store-only fields
# (not indexed in the dictionary)

# TODO:
#   use enc_string and dec_string!

with 'Krawfish::Koral::Document::Field';


sub type {
  'attachement'
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


sub sortable { 0 }


sub to_string {
  my ($self, $id) = @_;
  my $str = '';
  if (!$self->{key} || ($id && $self->{key_id})) {
    $str .= '#' . $self->key_id;
  }
  else {
    $str .= squote($self->key);
  };
  return $str . '=' . aquote($self->value);
};

1;
