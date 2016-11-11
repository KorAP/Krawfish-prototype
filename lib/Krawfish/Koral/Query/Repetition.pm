package Krawfish::Koral::Query::Repetition;
use parent 'Krawfish::Koral::Query';
use strict;
use warnings;

sub new {
  my $class = shift;
  my $span = shift;

  my ($min, $max);
  # {1,4}
  # {,4}
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
  else {
    $min = $max = 1;
  };

  $min //= 0;

  bless {
    span => $span,
    min => $min,
    max => $max
  }, $class;
};


sub min {
  $_[0]->{min}
};


sub max {
  $_[0]->{max}
};


# Return KoralQuery fragment
sub to_koral_fragment {
  my $self = shift;
  return {
    '@type' => 'koral:group',
    'operation' => 'operation:repetition',
    'boundary' => $self->_boundary,
    'operands' => [
      $self->{span}->to_koral_fragment
    ]
  };
};


sub _boundary {
  my $self = shift;
  my %hash = (
    '@type' => 'koral:boundary'
  );
  $hash{min} = $self->{min} if defined $self->{min};
  $hash{max} = $self->{max} if defined $self->{max};
  return \%hash;
}


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
  $_[0]->is_any;
};

sub is_extended_right {
  $_[0]->is_extended;
};

sub type { 'repetition' };

sub plan_for {
  ...
};


sub to_string {
  my $self = shift;
  my $str = $self->{span}->to_string;

  if (defined $self->{max}) {
    if ($self->{min} == $self->{max}) {
      $str .= '{' . $self->{min} . '}';
    }
    else {
      $str .= '{' . $self->{min} . ',' . $self->{max} . '}';
    }
  }
  elsif (defined $self->{min}) {
    $str .= '{' . $self->{min} . ',}';
  }
  elsif (defined $self->{max}) {
    $str .= '{,' . $self->{max} . '}';
  };
  return $str;
};

1;


__END__

