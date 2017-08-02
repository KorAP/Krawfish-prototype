package Krawfish::Koral::Query::Constraint::ClassDistance;
use Krawfish::Query::Constraint::ClassDistance;
use strict;
use warnings;

# This will add a class to the distance between both queries

# TODO: Rename to ClassBetween

sub new {
  my $class = shift;
  my $nr = shift // 1;
  bless \$nr, $class;
};

sub type {
  'constr_class';
};


# stringification
sub to_string {
  my $self = shift;
  return 'class=' . $$self;
};


# Normalize the constraint (do nothing)
sub normalize {
  $_[0];
};


# Identify the constraint (do nothing)
sub identify {
  $_[0];
};


# Optimize the constraint
sub optimize {
  my $self = shift;
  Krawfish::Query::Constraint::ClassDistance->new($$self);
};


# The minimum number of tokens for the constraint
# Is actual at least one token - but could be optional
sub min_span {
  0;
};


# Maximum number of tokens for the constraint
sub max_span {
  -1;
};


1;
