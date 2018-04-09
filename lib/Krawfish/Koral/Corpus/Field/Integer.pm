package Krawfish::Koral::Corpus::Field::Integer;
use Krawfish::Util::Constants ':PREFIX';
use Scalar::Util qw/looks_like_number/;
use Krawfish::Log;
use Role::Tiny::With;
use strict;
use warnings;

with 'Krawfish::Koral::Corpus::Field';
with 'Krawfish::Koral::Corpus::Field::Relational';
with 'Krawfish::Koral::Corpus';

# TODO:
#   Support a method to_int for range queries!

use constant DEBUG => 0;

# Construct new date field object
sub new {
  my $class = shift;
  bless {
    key => shift
  }, $class;
};

sub key_type {
  'int';
};

sub value_geq {
  my ($self, $other) = @_;
  return $self->value ge $other->value;
};

sub value_leq {
  my ($self, $other) = @_;
  return $self->value le $other->value;
};


# Translate all terms to term ids
sub identify {
  my ($self, $dict) = @_;

  if ($self->match_short ne '=') {
    warn 'Relational matches not supported yet';
    return;
  };

  my $term = $self->to_term;

  print_log('kq_int', "Translate term $term to term_id") if DEBUG;

  my $term_id = $dict->term_id_by_term(INT_FIELD_PREF . $term);

  return $self->builder->nowhere unless defined $term_id;

  return Krawfish::Koral::Corpus::FieldID->new($term_id);
};


# Compare against another field value
sub value_eq {
  my ($self, $other) = @_;
  return $self->value == $other->value;
};


sub value {
  my $self = shift;
  if (@_) {
    if (looks_like_number($_[0])) {
      $self->{value} = shift;
      return $self;
    };

    warn $_[0] . ' does nout look like a number';
    return;
  };
  return $self->{value};
};

# TODO:
# sub value_string {
#   # PREPEND WITH ZEROS
# };



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


1;
