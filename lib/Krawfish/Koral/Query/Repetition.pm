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
  return 0 if $self->is_null;
  return 1 unless $self->min;
  0;
};

sub is_null {
  return 1 if defined $_[0]->{max} && $_[0]->{max} == 0;
  0;
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


sub plan_for {
  my $self = shift;
  my $index = shift;

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
}

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

