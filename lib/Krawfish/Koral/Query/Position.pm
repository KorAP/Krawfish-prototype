package Krawfish::Koral::Query::Position;
use parent 'Krawfish::Koral::Query';
use strict;
use warnings;

sub new {
  my $class = shift;
  my ($exclude, $frame_array, $first, $second) = @_;

  bless {
    exclude => $exclude,
    frames  => _frame($frame_array),
    first   => $first,
    second  => $second
  }, $class;
};

# Return KoralQuery fragment
sub to_koral_fragment {
  my $self = shift;
  return {
    '@type' => 'koral:group',
    'operation' => 'operation:position',
    'frames' => [map { 'frames:' . $_ } _to_list($self->{frames})],
    'operands' => [
      $self->{first}->to_koral_query_fragment,
      $self->{second}->to_koral_query_fragment
    ]
  };
};

sub plan {
  my ($self, $index) = @_;

  my $frame_array = 
  
  return Krawfish::Query::Position->new(
    $self->{frames},
    $self->{first},
    $self->{second}
  );
};

sub _to_list {
...
};


# TODO: Should be exported, so not necessary
sub _frame ($) {
  my $array = shift;

  my $frame = 0b0000_0000_0000_0000;

  # Reference array
  $array = ref $array eq 'ARRAY' ? $array : [$array];

  # Iterate over all frames
  foreach (@$array) {

    # Check parameter
    if ($_ eq 'precedes_directly') {
      $frame |= 0b0000_0000_0000_0010;
    }
    elsif ($_ eq 'matches') {
      $frame |= 0b0000_0000_0010_0000;
    }
    else {
      warn "Unknown frame title $_!";
    };
  };

  return $frame;
};


1;


__END__

# Needs to be imported
# List all elements of a value
sub _to_list {
  my $val = shift;
  my @array = ();
  push @array, 'precedes'         if $val & PRECEDES;
  push @array, 'precedesDirectly' if $val & PRECEDES_DIRECTLY;
  push @array, 'overlapsLeft'     if $val & OVERLAPS_LEFT;
  push @array, 'alignsLeft'       if $val & ALIGNS_LEFT;
  push @array, 'startsWith'       if $val & STARTS_WITH;
  push @array, 'matches'          if $val & MATCHES;
  push @array, 'isWithin'         if $val & IS_WITHIN;
  push @array, 'isAround'         if $val & IS_AROUND;
  push @array, 'endsWith'         if $val & ENDS_WITH;
  push @array, 'alignsRight'      if $val & ALIGNS_RIGHT;
  push @array, 'overlapsRight'    if $val & OVERLAPS_RIGHT;
  push @array, 'succeedsDirectly' if $val & SUCCEEDS_DIRECTLY;
  push @array, 'succeeds'         if $val & SUCCEEDS;
  return @array;
};
