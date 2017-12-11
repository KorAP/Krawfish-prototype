package Krawfish::Koral::Query::Constraint::InBetween;
use Krawfish::Query::Constraint::InBetween;
use Role::Tiny::With;
use strict;
use warnings;

with 'Krawfish::Koral::Query::Constraint::Base';
with 'Krawfish::Koral::Query::Boundary';

# TODO:
#   Support foundry for tokenization
#   and gaps parameter.


sub new {
  my $class = shift;
  bless {
    min => shift // 0,
    max => shift
  }, $class;
};


sub type {
  'constr_dist';
};


# Stringify
sub to_string {
  my $self = shift;
  return 'between=' . (defined $self->{min} ? $self->{min} : 0) .
    '-' .
    (defined $self->{max} ? $self->{max} : 'INF');
};



# Normalize constraint
sub normalize {
  my $self = shift;

  my @constraints = ($self);

  # Introduce position constraint
  my @frames = qw/precedes succeeds/;
  if (!$self->{min} || $self->{min} == 0) {
    push @frames, qw/precedesDirectly succeedsDirectly/;
  };

  push @constraints, Krawfish::Koral::Query::Constraint::Position->new(@frames);

  return @constraints;
};


# Optimize constraint
sub optimize {
  my $self = shift;
  return Krawfish::Query::Constraint::InBetween->new(
    $self->{min},
    $self->{max}
  );
};


# The minimum number of tokens for the constraint
# Is actual at least one token - but could be optional
sub min_span {
  my ($self, $first_len, $second_len) = @_;

  if ($first_len == -1 || $second_len == -1) {
    return -1;
  };

  # return the joined lengths plus the minimal space between
  return $first_len + $second_len + $self->{min};
};


# Maximum number of tokens for the constraint
sub max_span {
  my ($self, $first_len, $second_len) = @_;

  # If the constraint or any operand is unbound, return unbound
  if (!defined $self->{max} || $first_len == -1 || $second_len == -1) {
    return -1;
  };

  # return the joined lengths plus the maximum space between
  return $first_len + $second_len + $self->{max};
};


# Deserialize
sub from_koral {
  my ($class, $kq) = @_;

  return $class->new(
    $class->from_koral_boundary(
      $kq->{boundary}
    )
  );
};


# serialize
sub to_koral_fragment {
  my $self = shift;

  return {
    '@type' => 'constraint:inBetween',
    boundary => $self->to_koral_boundary
  };
};


1;
