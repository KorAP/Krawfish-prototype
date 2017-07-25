package Krawfish::Koral::Query::Constraint::InBetween;
use Krawfish::Query::Constraint::InBetween;
use strict;
use warnings;

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
  'constr_class_distance';
};


# Stringify
sub to_string {
  my $self = shift;
  return 'between=' . (defined $self->{min} ? $self->{min} : 0) . '-' . (defined $self->{max} ? $self->{max} : 'INF');
};


# Probably introduce opt for min==0 constraint
sub normalize {
  $_[0];
};

sub inflate {
  $_[0];
};

# Optimize constraint
sub optimize {
  my ($self, $index) = @_;
  return Krawfish::Query::Constraint::InBetween->new($self->{min}, $self->{max});
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


1;
