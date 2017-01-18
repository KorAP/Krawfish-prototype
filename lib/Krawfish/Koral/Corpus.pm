package Krawfish::Koral::Corpus;
use strict;
use warnings;

# Creation of virtual corpus

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

sub is_negative {
  my $self = shift;
  if (scalar @_ == 1) {
    $self->{negative} = shift;
  };
  return $self->{negative} // 0;
};


#############################
# Query Application methods #
#############################

sub from_koral;

sub to_koral_fragment;


1;
