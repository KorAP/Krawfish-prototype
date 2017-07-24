package Krawfish::Koral::Query::Length;
use parent 'Krawfish::Koral::Query';
use Scalar::Util qw/looks_like_number/;
use List::Util;
use Krawfish::Query::Length;
use strict;
use warnings;

# TODO:
#   Normalize chained length queries
#   length(0-3,length(1-3,query))

# TODO:
#   Check for query invalidity based on min_span and max_span
#   length(2-4, [Baum]) - although, this only works with token support!

sub new {
  my $class = shift;
  my $span = shift;

  # Expect parameters min-length, max-length
  # and tokenization that is the base for length
  my ($min, $max, $token);

  # All parameters set
  if (@_ == 3) {
    ($min, $max, $token) = @_;
  }

  # Two parameters
  elsif (@_ == 2) {
    unless (looks_like_number($_[1])) {
      $min = $max = $_[0];
      $token = $_[1];
    }

    else {
      ($min, $max) = @_;
    };
  }

  # One parameter
  elsif (@_ == 1) {
    ($min, $max) = ($_[0], $_[0]);
  };

  if ($token) {
    warn 'Token definitions not yet supported!';
  };

  bless {
    operands => [$span],
    min => $min,
    max => $max,
    token => $token
  }, $class;
};


# Minimum length of either tokens or (default) subtokens
sub min {
  if (defined $_[1]) {
    $_[0]->{min} = $_[1];
    return $_[0];
  };
  $_[0]->{min};
};


# Minimum length of either tokens or (default) subtokens
sub max {
  if (defined $_[1]) {
    $_[0]->{max} = $_[1];
    return $_[0];
  };
  $_[0]->{max};
};


# Minimum span of the query in tokens
sub min_span {
  my $self = shift;

  # As per tokens are not supported,
  # min( refers to the minimum number of subtokens
  # As min_span refers to tokens and one token has, as minumum,
  # one subtoken, both values can't be compared. That's why
  # min_span of the operand is returned, as long as it is not 0.

  my $min_span = $self->operand->min_span;
  $min_span = $min_span == 0 ? ($self->min >= 1 ? 1 : 0) : $min_span;

  my $max_span = $self->max_span;

  return ($max_span != -1 && $max_span < $min_span) ? $max_span : $min_span;
};



# Maximum span of the query
sub max_span {
  my $self = shift;

  # As max_span refers to tokens and max refers
  # (as long tokens are not supported) subtokens,
  # those values are not interchangeable.
  # But one token spans at least one subtoken, so
  # if the subtoken boundary is smaller as max_span,
  # this is the new max_span.

  my $max_span = $self->operand->max_span;

  if ($max_span == -1) {
    return -1;
  }

  elsif ($self->max < $max_span) {
    return $self->max;
  };

  return $max_span;
};


sub token_base {
  if (defined $_[1]) {
    $_[0]->{token} = $_[1];
    return $_[0];
  };
  $_[0]->{token};
};


sub type { 'length' };


sub to_koral_fragment {
  ...
};


# Normalize query
sub normalize {
  my $self = shift;

  # Length is null
  if ($self->{max} == 0) {
    return $self->builder->null;
  };

  my $span;
  unless ($span = $self->operand->normalize) {
    $self->copy_info_from($self->operand);
    return;
  };

  # Span is null or nothing
  if ($span->is_null) {
    return $self->builder->null;
  };

  if ($span->is_nothing) {
    return $self->builder->nothing;
  };

  # Matches anywhere
  #  if ($span->is_any) {

  # TODO: Check for repetition!!!
    # if ($self->type)
    #
    #return $self->builder->repeat(
    #  $self->builder->any,
    #  $self->min,
    #  $self->max
    #)->normalize;

  #  };

  # No boundaries given
  if (!defined $self->{min} && !defined $self->{max}) {
    return $span;
  };

  # Check the length for plausibility
  my $min = $self->min_span; # Is tokens, may span more subtokens
  my $max = $self->max;

  if ($min < $self->min) {
    $min = $self->min;
  };

  # The length is not plausible
  if (defined $min && defined $max && ($min > $max)) {

    # Cannot match
    return $self->builder->nothing;
  };

  $self->operands([$span]);

  return $self;
};


# Optimize query
sub optimize {
  my ($self, $index) = @_;

  # TODO: Add constraint instead of query, if implemented

  my $span = $self->operand->optimize($index);

  # Nothing set
  if ($span->max_freq == 0) {
    return Krawfish::Query::Nothing->new;
  };

  return Krawfish::Query::Length->new(
    $span,
    $self->{min},
    $self->{max},
    $self->{token}
  );
};


sub maybe_unsorted {
  $_[0]->operand->maybe_unsorted;
};


sub from_koral;


sub to_string {
  my $self = shift;
  my $str = 'length(';
  $str .= $self->{min} // '0';
  $str .= '-';
  $str .= $self->{max} // 'inf';
  $str .= ';' . $self->{token} if $self->{token};
  $str .= ':';
  $str .= $self->operand->to_string;
  return $str . ')';
};

sub is_any { $_[0]->operand->is_any };


sub is_optional {
  my $self = shift;
  if ($self->{min} == 0 && $self->operand->is_optional) {
    return 1;
  };
  return;
};


sub is_null {
  return 1 if $_[0]->{max} == 0;
  return $_[0]->operand->is_null
};

sub is_negative { $_[0]->operand->is_negative };

sub is_extended_right { $_[0]->operand->is_extended_right };

sub is_extended_left { $_[0]->operand->is_extended_left };

1;
