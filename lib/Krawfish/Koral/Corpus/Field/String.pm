package Krawfish::Koral::Corpus::Field::String;
use Krawfish::Util::String qw/normalize_nfkc/;
use Krawfish::Util::Constants ':PREFIX';
use Role::Tiny::With;
use strict;
use warnings;

with 'Krawfish::Koral::Corpus::Field';
with 'Krawfish::Koral::Corpus';

use constant DEBUG => 0;


sub new {
  my $class = shift;
  bless {
    key => shift
  }, $class;
};


sub key_type {
  'string';
};

# Translate all terms to term ids
sub identify {
  my ($self, $dict) = @_;

  if ($self->match_short ne '=' &&
        $self->match_short ne '~') {
    warn 'Relational matches not supported yet: ' . $self->match_short;
    return;
  };

  my $term = $self->to_term;

  print_log('kq_term', "Translate term $term to term_id") if DEBUG;

  my $term_id = $dict->term_id_by_term(FIELD_PREF . $term);

  return $self->builder->nowhere unless defined $term_id;

  return Krawfish::Koral::Corpus::FieldID->new($term_id);
};


# Compare against another field value
sub value_eq {
  my ($self, $other) = @_;
  if ($self->value eq $other->value) {
    return 1;
  };
  return 0;
};


# Stringification for sorting
# TODO:
#   This may fail in case key_type and/or
#   value may contain ':' - so this should be
#   ensured!
sub to_sort_string {
  my $self = shift;
  return 0 if $self->is_null;

  my $str = $self->key_type . ':';
  $str .= $self->key . ':';
  $str .= ($self->value_string // '') . ':';
  $str .= $self->match_short;
  return $str;
};


sub normalize {
  my $self = shift;
  $self->{value} = normalize_nfkc($self->value) if $self->value;
  $self->{key} = normalize_nfkc($self->key) if $self->key;
  return $self;
};


1;
