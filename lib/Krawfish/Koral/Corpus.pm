package Krawfish::Koral::Corpus;
use parent 'Krawfish::Info';
# TODO: Use the same parent as Koral::Query
use Krawfish::Koral::Corpus::Builder;
use strict;
use warnings;

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
sub plan_for;

# This will check for subcorpora
# having classes. Subcorpora with classes
# can't be cached.
sub has_classes {
  0;
};

# This will remove classes
# in subcorpora
sub plan_without_classes_for {
  ...;
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
