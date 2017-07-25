package Krawfish::Koral::Query::Constraint::NotBetween;
use Krawfish::Query::Constraint::NotBetween;
use Krawfish::Koral::Query::Constraint::InBetween;
use Krawfish::Koral::Query::Constraint::ClassDistance;
use Krawfish::Koral::Query::Constraint::Position;
use strict;
use warnings;

# Check that a query between two operands is does nmot occur.
# In case this operand never occurs, it will at least set a relevant length.

# TODO:
#   Check min_tokens and max_tokens

sub new {
  my $class = shift;
  bless {
    query => shift
  }, $class;
};


sub type {
  'constr_not';
};


# stringify
sub to_string {
  my $self = shift;
  return 'notBetween=' . $self->{query}->to_string;
};


# Normalize constraint
sub normalize {
  my $self = shift;

  my $query;
  unless ($query = $self->{query}->normalize) {
    # TODO something like this: $self->copy_info_from($self->span);
    return;
  };

  my @constraints = ($self);

  # Wrap out the classes
  while ($query->type eq 'class') {
    push @constraints, Krawfish::Koral::Query::Constraint::ClassDistance->new($query->number);
    $query = $query->operand;
  };

  # Remove all inner classes here, because they can't occur
  $query = $query->remove_classes;

  # Store new query
  $self->{query} = $query;

  my $min_span = $query->min_span;
  my $max_span = $query->max_span;

  # Introduce in_between constraint
  if ($max_span != -1) {
    $min_span = 0 if $min_span == -1;
    my $in_between = Krawfish::Koral::Query::Constraint::InBetween->new($min_span, $max_span);
    unshift @constraints, $in_between;
  };

  # Introduce positional constraint
  my @frames;
  if ($min_span == 0 || $min_span == -1) {
    push @frames, qw/precedesDirectly succeedsDirectly/;
  };
  if ($max_span > 0 || $max_span == -1) {
    push @frames, qw/precedes succeeds/;
  };

  push @constraints, Krawfish::Koral::Query::Constraint::Position->new(@frames);

  return @constraints;
};


# Optimize constraint
sub optimize {
  my ($self, $index) = @_;

  # Optimize query
  my $query = $self->{query}->optimize($index);

  # Span has no match
  return if $query->max_freq == 0;

  # Return valid constraint
  return Krawfish::Query::Constraint::NotBetween->new($query);
};


# The minimum number of tokens for the constraint
sub min_span {
  my ($self, $first_len, $second_len) = @_;
  my $neg_len = $self->{query}->min_span;

  # One operand is unbound
  if ($first_len == -1 || $second_len == -1 || $neg_len == -1) {
    return -1;
  };

  return $first_len + $second_len + $neg_len;
};


# Maximum number of tokens for the constraint
sub max_span {
  my ($self, $first_len, $second_len) = @_;
  my $neg_len = $self->{query}->max_span;

  # One operand is unbound
  if ($first_len == -1 || $second_len == -1 || $neg_len == -1) {
    return -1;
  };
  return $first_len + $second_len + $neg_len;
};


# Inflate negation
sub inflate {
  my ($self, $dict) = @_;
  $self->{query} = $self->{query}->inflate($dict);
  $self;
};


1;
