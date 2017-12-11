package Krawfish::Koral::Query::Constraint::ClassBetween;
use Krawfish::Query::Constraint::ClassBetween;
use Role::Tiny::With;
use strict;
use warnings;

with 'Krawfish::Koral::Query::Constraint::Base';

# This will add a class to the distance between both queries

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


# Optimize the constraint
sub optimize {
  my $self = shift;
  Krawfish::Query::Constraint::ClassBetween->new($$self);
};


# Deserialize
sub from_koral {
  my ($class, $kq) = @_;
  my $nr = $kq->{classOut};
  return $class->new($nr);
};


# Serialize
sub to_koral_fragment {
  my $self = shift;
  return {
    '@type' => 'constraint:classBetween',
    'classOut' => $$self
  };
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
