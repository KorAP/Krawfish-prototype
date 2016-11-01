package Krawfish::Koral::Corpus;
use strict;
use warnings;

# Creation of virtual corpus

sub new {
  my $class = shift;
  bless {}, $class;
};

##########################
# Query Planning methods #
##########################

# Rewrite query to actual query
sub plan;

#############################
# Query Application methods #
#############################

sub from_koral;

sub to_koral_fragment;


1;
