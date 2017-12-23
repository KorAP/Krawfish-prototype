package Krawfish::Koral::Query::Repetition;
use Role::Tiny::With;
use Krawfish::Query::Repetition;
use strict;
use warnings;

with 'Krawfish::Koral::Query';
with 'Krawfish::Koral::Query::Boundary';

our $MAX = 100;

sub new {
  my $class = shift;
  my $span = shift;

  my ($min, $max);
  # {1,4}, {,4}
  # {0,1} # ?
  # {1,}  # +
  # {0,}  # *
  if (@_ == 2) {
    ($min, $max) = @_;
  }
  # {5}
  elsif (@_ == 1) {
    $min = $max = shift;
  }
  # *
  else {
    $min = $max = undef;
  };

  bless {
    operands => [$span],
    min => $min,
    max => $max
  }, $class;
};


# Get the minimum span
sub min_span {
  my $self = shift;

  # This needs to be stored,
  # otherwise the value changes after normalization
  return $self->{min_span} if defined $self->{min_span};
  $self->{min_span} = $self->operand->min_span * ($self->min // 0);
  return $self->{min_span};
};


# Get the maximum span
sub max_span {
  my $self = shift;
  return $self->{max_span} if defined $self->{max_span};

  # This needs to be stored,
  # otherwise the value changes after normalization
  # Either repetition is unbound or the operand is unbound,
  # Return unbound
  if (!defined $self->max || $self->operand->max_span == -1) {
    $self->{max_span} = -1;
  }
  else {
    $self->{max_span} = $self->operand->max_span * $self->max;
  };
  return $self->{max_span};
};


# Return KoralQuery fragment
sub to_koral_fragment {
  my $self = shift;
  return {
    '@type' => 'koral:group',
    'operation' => 'operation:repetition',
    'boundary' => $self->to_koral_boundary,
    'operands' => [
      $self->operand->to_koral_fragment
    ]
  };
};

sub from_koral {
  my ($class, $kq) = @_;

  my ($min, $max) = $class->from_koral_boundary($kq->{boundary});

  my $qb = $class->builder;

  # Get operand
  my $op = $qb->from_koral(
    $kq->{operands}->[0]
  );

  $class->new($op, $min, $max);
};


#########################################
# Query Planning methods and attributes #
#########################################

sub is_anywhere {
  $_[0]->operand->is_anywhere;
};


sub is_optional {
  my $self = shift;
  if (defined $_[0] && $_[0] == 0) {

    # Set to 1, if query is not allowed to be optional,
    # although query is optional
    unless ($self->min) {
      $self->min(1);
    };
  };
  return 0 if $self->is_null;
  return 1 unless $self->min;
  0;
};

sub is_null {
  return 1 if defined $_[0]->{max} && $_[0]->{max} == 0;
  0;
};


sub is_negative {
  $_[0]->operand->is_negative;
};


sub is_extended {
  return 0 if $_[0]->is_null;

  # Is extended, in case the repetition is anywhere
  $_[0]->is_anywhere;
};

sub is_extended_right {
  $_[0]->is_extended;
};

sub type { 'repetition' };



# TODO:
#   If the query is a class query, reverse the hierarchical ordering!
# Normalize the query
sub normalize {
  my $self = shift;

  # Call min_span and max_span to precalculate and remember values
  $self->min_span and $self->max_span;

  # Normalize so classes always wrap repetitions and not the other way around
  while ($self->operand->type eq 'class') {
    my $nr = $self->operand->number;
    my $ops = $self->operand->operands;

    # Make the class operands the current ops of the repetition
    $self->operands($ops);

    return $self->builder->class($self, $nr)->normalize;
  };

  # Copy messages from span serialization
  my $span;
  unless ($span = $self->operand->normalize) {
    $self->copy_info_from($self->operand);
    return;
  };

  # If something does not match, but is optional at the same time,
  # Make it ignorable
  if ($span->is_nowhere && $self->is_optional) {
    return $self->builder->null;
  };

  $self->operands([$span]);

  my $min = $self->{min};
  my $max = $self->{max};

  $min //= 0;

  if (!$max || $max > $MAX) {
    $self->warning(000, 'Maximum value is limited', $MAX);
    $max = $MAX;
  };

  if ($min > $max) {
    $self->error(000, 'Minimum has to be greater than maximum in repetition');
    return;
  };

  if ($min < 0) {
    $self->warning(000, 'Minimum has to be greater or equal than 0');
    $min = 0;
  };

  $self->min($min);
  $self->max($max);

  # [a]{1,1} -> [a]
  if ($min == 1 && $max == 1) {
    return $self->operand;
  };

  return $self;
};


# Finalize the query
sub finalize {
  my $self = shift;

  my $min = $self->{min};
  my $max = $self->{max};

  # Some errors

  if ($min == 0) {
    $self->warning(781, 'Optionality of query is ignored');
    $self->min(1);
  };

  # Copy messages from span serialization
  my $span;
  unless ($span = $self->operand->finalize) {

    $self->copy_info_from($self->operand);
    return;
  };

  # [a]{1,1} -> [a]
  if ($self->{min} == 1 && $self->{max} == 1) {
    $span->copy_info_from($self);
    return $span;
  };


  if ($min == 1 && $max == 1) {
    return $span;
  };

  # Finalize the span
  $self->operands([$span]);

  return $self;
};


# Optimize for segment
sub optimize {
  my ($self, $segment) = @_;

  # optimize span query
  my $span = $self->operand->optimize($segment);

  # Span matches nowhere
  return $span if $span->max_freq == 0;

  # Create repetition span
  return Krawfish::Query::Repetition->new(
    $span,
    $self->{min},
    $self->{max}
  );
};


sub maybe_unsorted {
  $_[0]->operand->maybe_unsorted;
};



sub to_string {
  my ($self, $id) = @_;

  my $str = $self->operand->to_string($id);

  my $type = $self->operand->type;

  # Wrap complex queries in parentheses
  if ($type !~ /class|token|term|span|nowhere/) {
    $str = '(' . $str . ')';
  };

  if (defined $self->{min} && defined $self->{max}) {
    if (!$self->{min} && $self->{max} == 1) {
      $str .= '?';
    }
    elsif ($self->{min} == $self->{max}) {
      $str .= '{' . $self->{min} . '}';
    }
    else {
      $str .= '{' . $self->{min} . ',' . $self->{max} . '}';
    }
  }
  elsif ($self->{min}) {
    if ($self->{min} == 1) {
      $str .= '+';
    }
    else {
      $str .= '{' . $self->{min} . ',}';
    };
  }
  elsif (defined $self->{max}) {
    if ($self->{max} == 1) {
      $str .= '?';
    }
    else {
      $str .= '{,' . $self->{max} . '}';
    };
  }
  else {
    $str .= '*';
  };
  return $str;
};

1;


__END__

