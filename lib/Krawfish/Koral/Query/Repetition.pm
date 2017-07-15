package Krawfish::Koral::Query::Repetition;
use parent 'Krawfish::Koral::Query';
use Krawfish::Query::Repetition;
use strict;
use warnings;

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
    span => $span,
    min => $min,
    max => $max
  }, $class;
};


sub min {
  if (defined $_[1]) {
    $_[0]->{min} = $_[1];
    return $_[0];
  };
  $_[0]->{min};
};


sub max {
  if (defined $_[1]) {
    $_[0]->{max} = $_[1];
    return $_[0];
  };
  $_[0]->{max};
};


sub span {
  $_[0]->{span};
};

# Return KoralQuery fragment
sub to_koral_fragment {
  my $self = shift;
  return {
    '@type' => 'koral:group',
    'operation' => 'operation:repetition',
    'boundary' => $self->boundary,
    'operands' => [
      $self->{span}->to_koral_fragment
    ]
  };
};


#########################################
# Query Planning methods and attributes #
#########################################

sub is_any {
  $_[0]->{span}->is_any;
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
  $_[0]->{span}->is_negative;
};


sub is_extended {
  return 0 if $_[0]->is_null;

  # Is extended, in case the repetition is any
  $_[0]->is_any;
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


  # Copy messages from span serialization
  my $span;
  unless ($span = $self->{span}->normalize) {
    $self->copy_info_from($self->{span});
    return;
  };

  # If something does not match, but is optional at the same time,
  # Make it ignorable
  if ($span->is_nothing && $self->is_optional) {
    return $self->builder->null->normalize;
  };


  $self->{span} = $span;

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
    return $self->{span};
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
  unless ($span = $self->{span}->finalize) {

    $self->copy_info_from($self->{span});
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
  $self->{span} = $span;

  return $self;
};


# Optimize for index
sub optimize {
  my ($self, $index) = @_;

  # optimize span query
  my $span = $self->{span}->optimize($index);

  # Span matches nowhere
  return $span if $span->freq == 0;

  # Create repetition span
  return Krawfish::Query::Repetition->new(
    $span,
    $self->{min},
    $self->{max}
  );
};


sub plan_for {
  my $self = shift;
  my $index = shift;

  warn 'DEPRECATED';

  # Copy messages from span serialization
  my $span;
  unless ($span = $self->{span}->plan_for($index)) {
    $self->copy_info_from($self->{span});
    return;
  };

  my $min = $self->{min};
  my $max = $self->{max};

  $min //= 0;

  if (!$max || $max > $MAX) {
    $self->warning(000, 'Maximum value is limited', $MAX);
    $max = $MAX;
  };

  # Some errors
  if ($min > $max) {
    $self->error(000, 'Minimum has to be greater than maximum in repetition');
    return;
  }
  elsif ($min == 0) {
    $self->error(000, 'Optionality is ignored');
    return;
  }
  elsif ($min < 0) {
    $self->error(000, 'Minimum has to be greater than 0');
    return;
  };

  if ($min == 1 && $max == 1) {
    return $span;
  };

  return Krawfish::Query::Repetition->new($span, $min, $max);
};


# Filter by corpus
sub filter_by {
  my $self = shift;
  $self->{plan}->filter_by(shift);
};


sub maybe_unsorted {
  $_[0]->{span}->maybe_unsorded;
};



sub to_string {
  my $self = shift;
  my $str = $self->{span}->to_string;

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

