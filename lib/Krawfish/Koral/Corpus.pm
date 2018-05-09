package Krawfish::Koral::Corpus;
use strict;
use warnings;
use Role::Tiny;
use Krawfish::Koral::Corpus::Builder;
use Krawfish::Log;

# TODO: Use the same role as Koral::Query

# TODO: Add this everywhere
with 'Krawfish::Koral::Report';

# Override:
#   normalize
#   operands
#   finalize
#   has_classes
#   remove_classes
#   identify
#   is_negative
#   is_anywhere
#   is_nowhere
#   is_null
#   is_leaf
#   to_neutral
requires qw/optimize
            type
            to_string
            from_koral
            to_koral_fragment/;

use constant DEBUG => 0;

# Base object for virtual corpus queries

# Constructor
#sub new {
#  my $class = shift;
#  bless {}, $class;
#};

#########################################
# Query Planning methods and attributes #
#########################################


# Normalize the query
sub normalize {
  $_[0];
};


# Refer to common subqueries
sub refer {
  $_[0];
};


# Get operands
sub operands {
  my $self = shift;
  if (@_) {
    $self->{operands} = shift;
  };
  $self->{operands};
};


# Get and set first and only operand
sub operand {
  if (@_ == 2) {
    $_[0]->{operands} = [$_[1]];
  };
  $_[0]->{operands}->[0];
};


# Check for cached subqueries
sub cache {
  $_[0];
};


# This is the class to be overwritten
# by subclasses
sub _finalize {
  $_[0];
};


# Normalize to be on the root
sub finalize {
  my $self = shift;
  my $corpus = $self;

  print_log('kq_corpus', 'Finalize tree or field') if DEBUG;

  $corpus = $corpus->_finalize;

  # Realize term queries
  my $temp_corpus_1 = $corpus->to_term_query;

  # In case the result is different and is a field group - normalize again
  if ($temp_corpus_1) {
    if (Role::Tiny::does_role($temp_corpus_1, 'Krawfish::Koral::Util::Boolean') &&
        (my $temp_corpus_2 = $temp_corpus_1->normalize)) {
      $corpus = $temp_corpus_2;
    }
    else {
      $corpus = $temp_corpus_1;
    };
  };

  if ($corpus->is_negative) {

    print_log('kq_corpus', 'Query is negative') if DEBUG;

    # Toggle negativity
    $corpus->is_negative(0);

    print_log('kq_corpus', 'Do an "andNot" on anywhere') if DEBUG;

    return $self->builder->bool_and_not(
      $self->builder->anywhere,
      $corpus
    );
  };

  print_log('kq_corpus', 'Do an "and" on anywhere') if DEBUG;

  # Do not wrap already satisfied queries
  return $corpus if $corpus->is_anywhere || $corpus->is_nowhere;

  return $self->builder->bool_and(
    $self->builder->anywhere,
    $corpus
  );
};


# This will check for subcorpora
# having classes. Subcorpora with classes
# can't be cached.
sub has_classes {
  # TODO:
  #   Memoize!

  my $self = shift;

  return if $self->is_leaf;

  my $ops = $self->operands;

  return 0 unless $ops;

  for (my $i = 0; $i < @$ops; $i++) {
    return 1 if $ops->[$i]->has_classes;
  };
  return 0;
};


# Remove any classes
sub remove_classes {
  my $self = shift;
  return $self if $self->is_leaf;
  my $ops = $self->operands;
  return $self unless $ops;
  for (my $i = 0; $i < @$ops; $i++) {
    $ops->[$i] = $ops->[$i]->remove_classes;
  };
  return $self;
};


# TODO:
#   If "nothing" returns, optimize away
#   before ->optimize().
sub identify {
  my ($self, $dict) = @_;

  return $self if $self->is_leaf;
  my $ops = $self->operands;
  return $self unless $ops;
  for (my $i = 0; $i < @$ops; $i++) {
    $ops->[$i] = $ops->[$i]->identify($dict);
  };
  return $self;
};


# Corpus is negative
sub is_negative {
  my $self = shift;
  if (scalar @_ == 1) {
    $self->{negative} = shift;
    return $self;
  };
  return $self->{negative} // 0;
};


# Toggle negativity of corpus
sub toggle_negative {
  my $self = shift;
  $self->is_negative($self->is_negative ? 0 : 1);
  return $self;
};


# Matches everything
sub is_anywhere {
  my $self = shift;
  if (defined $_[0]) {
    $self->{anywhere} = shift;
  };
  return $self->{anywhere} // 0;
};


# Matches nowhere
sub is_nowhere {
  my $self = shift;
  if (defined $_[0]) {
    $self->{nowhere} = shift;
  };
  return $self->{nowhere} // 0;
};


# Matches nowhere
# (in the sequence sense of "der >alte*< Mann")
sub is_null {
  0;
};


# Query is leaf
sub is_leaf {
  0;
};


# Create KoralQuery builder
sub builder {
  return Krawfish::Koral::Corpus::Builder->new;
};


# Serialize to neutral string
sub to_neutral {
  $_[0]->to_string;
};

# Stringification for sorting
sub to_sort_string {
  $_[0]->to_string;
};


# Realize as a term query
sub to_term_query {
  my $self = shift;
  my $changes = 0;

  return $self unless $self->operands;

  my $ops = $self->operands;
  return $self unless $ops;

  for (my $i = 0; $i < @$ops; $i++) {
    my $real = $ops->[$i]->to_term_query;
    if ($real) {
      $ops->[$i] = $real;
      $changes++;
    };
  };
  return $self if $changes;
  return;
};


1;
