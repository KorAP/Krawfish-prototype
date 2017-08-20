package Krawfish::Koral::Document::FieldInt;
use Krawfish::Util::String qw/squote/;
use Role::Tiny::With;
with 'Krawfish::Koral::Document::FieldBase';
use warnings;
use strict;

# Class for integer fields


sub type {
  'int';
};


sub identify {
  my ($self, $dict) = @_;

  return if $self->{key_id} && $self->{key_value_id};

  # Get or introduce new key term_id
  my $key  = '!' . $self->{key};
  $self->{key_id} = $dict->add_term($key);

  # Set sortable
  if (my $collation = $dict->collation($self->{key_id})) {
    $self->{sortable} = 1;
  };

  # Get or introduce new key term_id
  my $term = '+' . $self->{key} . ':' . $self->{value};
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
