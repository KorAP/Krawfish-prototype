package Krawfish::Koral::Document::FieldInt;
use Krawfish::Util::String qw/squote/;
use Krawfish::Util::Constants qw/:PREFIX/;
use Krawfish::Log;
use Role::Tiny::With;
with 'Krawfish::Koral::Document::FieldBase';
use warnings;
use strict;

use constant DEBUG => 1;

# Class for integer fields


sub type {
  'int';
};


sub identify {
  my ($self, $dict) = @_;

  return if $self->{key_id} && $self->{key_value_id};

  # Get or introduce new key term_id
  my $key  = KEY_PREF . $self->{key};
  $self->{key_id} = $dict->add_term($key);

  if (DEBUG) {
    print_log('k_doc_fint', 'Check for sortability for ' . $self->{key_id});
  };

  # Set sortable
  if (my $collation = $dict->collation($self->{key_id})) {
    if (DEBUG) {
      print_log('k_doc_fint', 'Field ' . $self->{key_id} . ' is sortable');
    };

    $self->{sortable} = 1;
  };

  # Get or introduce new key term_id
  my $term = FIELD_PREF . $self->{key} . ':' . $self->{value};
  $self->{key_value_id} = $dict->add_term($term);

  return $self;
};


sub to_string {
  my $self = shift;
  unless ($self->{key_id}) {
    return squote($self->{key}) . '=' . $self->{value};
  };
  return '#' . $self->{key_id} . '=' . '#' . $self->{key_value_id} . '(' . $self->{value} . ')';
};




1;
