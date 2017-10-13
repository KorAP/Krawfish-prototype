package Krawfish::Koral::Corpus;
use Role::Tiny::With;
with 'Krawfish::Koral::Info';
# TODO: Use the same parent as Koral::Query
use Krawfish::Koral::Corpus::Builder;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

# Base object for virtual corpus queries

# Constructor
sub new {
  my $class = shift;
  bless {}, $class;
};

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


# Optimize for an index
sub optimize {
  warn 'override';
};


# Normalize to be on the root
sub finalize {
  my $self = shift;

  print_log('kq_corpus', 'Finalize tree or field') if DEBUG;

  if ($self->is_negative) {

    print_log('kq_corpus', 'Query is negative') if DEBUG;

    # Toggle negativity
    $self->is_negative(0);

    print_log('kq_corpus', 'Do an "andNot" on anywhere') if DEBUG;

    return $self->builder->bool_and_not(
      $self->builder->anywhere,
      $self
    );
  }

  print_log('kq_corpus', 'Do an "and" on anywhere') if DEBUG;

  return $self->builder->bool_and(
    $self->builder->anywhere,
    $self
  );
};


# This will check for subcorpora
# having classes. Subcorpora with classes
# can't be cached.
sub has_classes {
  # TODO:
  #   Memoize!

  my $self = shift;
  my $ops = $self->operands;

  return 0 unless $ops;

  for (my $i = 0; $i < @$ops; $i++) {
    return 1 if $ops->[$i]->has_classes;
  };
  return 0;
};



# TODO:
#   If "nothing" returns, optimize away
#   before ->optimize().
sub identify {
  my ($self, $dict) = @_;

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


#############################
# Query Application methods #
#############################

# Deserialize
sub from_koral {
  warn 'override';
};


# serialize
sub to_koral_fragment {
  warn 'override';
};


# Stringification
sub to_string {
  warn 'override';
};


# Serialize to neutral string
sub to_neutral {
  $_[0]->to_string;
};


1;
