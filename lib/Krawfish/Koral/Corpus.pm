package Krawfish::Koral::Corpus;
use parent 'Krawfish::Info';
# TODO: Use the same parent as Koral::Query
use Krawfish::Koral::Corpus::Builder;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

# Creation of virtual corpus

# TODO:
#  Probably rename
#    is_nothing -> is_nowhere
#  and
#    is_any     -> is_everywhere

sub new {
  my $class = shift;
  bless {}, $class;
};

#########################################
# Query Planning methods and attributes #
#########################################

sub prepare_for {
  shift->plan_for(@_);
};


# Rewrite query to actual query
sub plan_for {
  warn 'DEPRECATED'
};


sub normalize {
  $_[0];
};

sub memoize {
  $_[0];
};

sub optimize;

# Normalize to be on the root
sub finalize {
  my $self = shift;

  print_log('kq_corpus', 'Finalize tree') if DEBUG;

  if ($self->is_negative) {

    print_log('kq_corpus', 'Query is negative') if DEBUG;

    # Toggle negativity
    $self->is_negative(0);
    return $self->builder->field_and_not(
      $self->builder->any,
      $self
    );
  }

  return $self->builder->field_and(
    $self->builder->any,
    $self
  );
};


# This will check for subcorpora
# having classes. Subcorpora with classes
# can't be cached.
sub has_classes {
  0;
};


# This will remove classes
# in subcorpora
sub plan_without_classes_for {
  warn 'Not yet implemented';
  shift->plan_for(@_);
};


sub is_negative {
  my $self = shift;
  if (scalar @_ == 1) {
    $self->{negative} = shift;
  };
  return $self->{negative} // 0;
};


sub toggle_negative {
  my $self = shift;
  $self->is_negative($self->is_negative ? 0 : 1);
  return $self;
};


# Matches everything
sub is_any {
  my $self = shift;
  if (defined $_[0]) {
    $self->{any} = shift;
  };
  return $self->{any} // 0;
};


# Matches nowhere
# (in the sequence sense of "der >alte*< Mann")
sub is_null {
  0;
};


sub is_nothing {
  my $self = shift;
  if (defined $_[0]) {
    $self->{nothing} = shift;
  };
  return $self->{nothing} // 0;
};


sub is_leaf { 0 };


# Create KoralQuery builder
sub builder {
  return Krawfish::Koral::Corpus::Builder->new;
};


#############################
# Query Application methods #
#############################

sub from_koral;


sub to_koral_fragment;


1;
