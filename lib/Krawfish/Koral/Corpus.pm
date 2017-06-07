package Krawfish::Koral::Corpus;
use parent 'Krawfish::Info';
# TODO: Use the same parent as Koral::Query
use Krawfish::Koral::Corpus::Builder;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 1;

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

sub plan_for {
  my ($self, $index) = @_;
  $self
    ->normalize
    ->finalize
    ->refer
    ->inflate
    ->cache
    ->optimize($index);
};


# This will remove classes
# in subcorpora
sub plan_without_classes_for {
  warn 'Not yet implemented';
  shift->plan_for(@_);
};


# Normalize the query
sub normalize {
  $_[0];
};


# Refer to common subqueries
sub refer {
  $_[0];
};


# Expand regular expressions ...
sub inflate {
  $_[0];
};


# Check for cached subqueries
sub cache {
  $_[0];
};


# Optimize for an index
sub optimize;


# Normalize to be on the root
sub finalize {
  my $self = shift;

  print_log('kq_corpus', 'Finalize tree or field') if DEBUG;

  if ($self->is_negative) {

    print_log('kq_corpus', 'Query is negative') if DEBUG;

    # Toggle negativity
    $self->is_negative(0);

  print_log('kq_corpus', 'Do an "andNot" on any') if DEBUG;
    return $self->builder->field_and_not(
      $self->builder->any,
      $self
    );
  }

  print_log('kq_corpus', 'Do an "and" on any') if DEBUG;

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
