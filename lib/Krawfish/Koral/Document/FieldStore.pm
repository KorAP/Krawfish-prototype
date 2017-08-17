package Krawfish::Koral::Document::FieldStore;
use Krawfish::Util::String qw/squote/;
use warnings;
use strict;

# Class for store-only fields
# (not indexed in the dictionary)

sub new {
  my $class = shift;
  # key, value
  bless { @_ }, $class;
};

sub type {
  'store'
};


sub key {
  $_[0]->{key};
};

sub key_id {
  $_[0]->{key_id};
};

sub term_id {
  # There is no term_id, but it's required for sorting
  undef;
};

sub value {
  $_[0]->{value};
};

sub identify {
  my ($self, $dict) = @_;

  my $key  = '!' . $self->{key};

  # Get key term_id
  # TODO:
  #   Add new method that introduces the term
  #   in case it doesn't exist
  my $key_id = $dict->term_id_by_term($key);

  # Not given yet
  if (defined $key_id) {
    $self->{key_id} = $key_id;
  }

  else {
    $self->{key_id} = $dict->add_term($key);
  };
  return $self;
};


sub to_string {
  my $self = shift;
  my $str = $self->{key_id} ? '#' . $self->{key_id} : squote($self->{key});
  return $str . '=' . squote($self->{value});
};


1;
