package Krawfish::Koral::Query::Position;
use parent 'Krawfish::Koral::Query';
use Krawfish::Query::Position;
use strict;
use warnings;

our %FRAME = (
  precedes => PRECEDES,
  precedesDirectly => PRECEDES_DIRECTLY,
  overlapsLeft => OVERLAPS_LEFT,
  alignsLeft => ALIGNS_LEFT,
  startsWith => STARTS_WITH,
  matches => MATCHES,
  isWithin => IS_WITHIN,
  isAround => IS_AROUND,
  endsWith => ENDS_WITH,
  alignsRight => ALIGNS_RIGHT,
  overlapsRight => OVERLAPS_RIGHT,
  succeedsDirectly => SUCCEEDS_DIRECTLY,
  succeeds => SUCCEEDS
);

sub new {
  my $class = shift;
  my ($exclude, $frame_array, $first, $second) = @_;

  bless {
    exclude => $exclude,
    frames  => _to_frame($frame_array),
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


# List all positions of a frame
sub _to_list {
  my $frame = shift;
  my @array = ();
  while (my ($key, $value) = %FRAME) {
    push @array, $key if $frame & $value;
  };
  return @array;
};


# Get the frame of a position list
sub _to_frame {
  my $array = shift;

  # Reference array
  $array = ref $array eq 'ARRAY' ? $array : [$array];

  my $frame = NULL_4;

  # Iterate over all frames
  foreach (@$array) {

    # Unify with frames
    $frame |= $FRAME{$_} or warn "Unknown frame title $_!";
  };
};


1;


__END__

