package Krawfish::Koral::Query::Position;
use parent 'Krawfish::Koral::Query';
use Krawfish::Query::Constraints;
use Krawfish::Query::Constraint::Position;
use Krawfish::Util::Bits;
use Krawfish::Log;
use Mojo::JSON;
use strict;
use warnings;

use constant DEBUG => 0;

# TODO:
#   This is identical to Koral::Constraint::Position,
#   so it should be DEPRECATED!


# TODO:
#  The query optimizer may change order of operands, because
#  the second operand should probably always be "simpler" regarding
#  payloads, as it will be buffered.


our %FRAME = (
  precedes         => PRECEDES,
  precedesDirectly => PRECEDES_DIRECTLY,
  overlapsLeft     => OVERLAPS_LEFT,
  alignsLeft       => ALIGNS_LEFT,
  startsWith       => STARTS_WITH,
  matches          => MATCHES,
  isWithin         => IS_WITHIN,
  isAround         => IS_AROUND,
  endsWith         => ENDS_WITH,
  alignsRight      => ALIGNS_RIGHT,
  overlapsRight    => OVERLAPS_RIGHT,
  succeedsDirectly => SUCCEEDS_DIRECTLY,
  succeeds         => SUCCEEDS
);

our $LEFT_FRAMES =
  PRECEDES |
  PRECEDES_DIRECTLY |
  OVERLAPS_LEFT |
  ALIGNS_LEFT |
  STARTS_WITH;
our $RIGHT_FRAMES =
  SUCCEEDS |
  SUCCEEDS_DIRECTLY |
  OVERLAPS_RIGHT |
  ALIGNS_RIGHT |
  ENDS_WITH;


sub new {
  my $class = shift;
  my ($frame_array, $first, $second) = @_;

  my $self = bless {
    first   => $first,
    second  => $second
  }, $class;

  $self->{frames}  = $self->_to_frame($frame_array);
  return $self;
};

# Return KoralQuery fragment
sub to_koral_fragment {
  my $self = shift;
  return {
    '@type' => 'koral:group',
    'operation' => 'operation:position',
    'frames' => [map { 'frames:' . $_ } $self->_to_list($self->{frames})],
    'operands' => [
      $self->{first}->to_koral_fragment,
      $self->{second}->to_koral_fragment
    ]
  };
};


#########################################
# Query Planning methods and attributes #
#########################################

sub type { 'position' };


# Filter by corpus
sub filter_by {
  my $self = shift;
  my $corpus_query = shift;
  $self->{first}->filter_by($corpus_query);
  $self->{second}->filter_by($corpus_query);
};


# List all positions of a frame
sub _to_list {
  my ($self, $frame) = @_;
  my @array = ();
  while (my ($key, $value) = %FRAME) {
    push @array, $key if $frame & $value;
  };
  return @array;
};


# Get the frame of a position list
sub _to_frame {
  my ($self, $array) = @_;

  # Reference array
  $array = ref $array eq 'ARRAY' ? $array : [$array];

  my $frame = NULL_4;

  # Iterate over all frames
  foreach (@$array) {

    # Unify with frames
    if (defined $FRAME{$_}) {
      $frame |= $FRAME{$_};
    }
    else {
      warn "Unknown frame title '$_'!"
    };
  };

  return $frame;
};


sub to_string {
  my $self = shift;
  my $string = 'pos(';
  $string .= (0 + $self->{frames}) . ':';
  $string .= $self->{first}->to_string . ',';
  $string .= $self->{second}->to_string;
  return $string . ')';
};


# Return if the query may result in an 'any' left extension
# [][Der]
sub is_extended_left {
  my $self = shift;

  # Already computed
  return $self->{is_extended_left}
    if $self->{is_extended_left};

  my $frames = $self->{frames};
  $frames = ~$frames if $self->{exclude};

  my $is_extended_left = 0;

  # The first span may be extended to the left
  if ($frames & (PRECEDES |
                   PRECEDES_DIRECTLY |
                   ENDS_WITH |
                   IS_AROUND |
                   OVERLAPS_LEFT)) {
    $is_extended_left = $self->{first}->is_extended_left;
  }

  # The second span may be extended to the left
  elsif ($frames & (SUCCEEDS |
                      SUCCEEDS_DIRECTLY |
                      ALIGNS_RIGHT |
                      IS_WITHIN |
                      OVERLAPS_RIGHT)) {
    $is_extended_left = $self->{second}->is_extended_left;
  }

  # Either spans may be extended to the left
  elsif ($frames & (STARTS_WITH |
                      ALIGNS_LEFT |
                      MATCHES)) {
    $is_extended_left = $self->{first}->is_extended_left ||
      $self->{second}->is_extended_left;
  };

  return $self->{is_extended_left} = $is_extended_left;
};


# Return if the query may result in an 'any' right extension
# [Der][]
sub is_extended_right {
  my $self = shift;

  # Already computed
  return $self->{is_extended_right} if $self->{is_extended_right};

  my $frames = $self->{frames};
  $frames = ~$frames if $self->{exclude};

  my $is_extended_right = 0;

  # The second span may be extended to the right
  if ($frames & (PRECEDES_DIRECTLY | PRECEDES | OVERLAPS_LEFT | IS_WITHIN | ALIGNS_LEFT)) {
    $is_extended_right = $self->{second}->is_extended_right;
  }

  # The first span may be extended to the right
  elsif ($frames & (SUCCEEDS_DIRECTLY | SUCCEEDS | OVERLAPS_RIGHT | IS_AROUND | STARTS_WITH)) {
    $is_extended_right = $self->{first}->is_extended_right;
  }

  # Either spans may be extended to the right
  elsif ($frames & (ALIGNS_RIGHT | ENDS_WITH | MATCHES)) {
    $is_extended_right =
      $self->{first}->is_extended_right ||
      $self->{second}->is_extended_right;
  };

  return $self->{is_extended_right} = $is_extended_right;
};


# return if the query is extended either to the left or to the right
sub is_extended {
  my $self = shift;
  return $self->is_extended_right || $self->is_extended_left;
};


sub maybe_unsorted {
  my $self = shift;
  my $frames = $self->{frames};

  return 1 if $self->{first}->maybe_unsorted or $self->{second}->maybe_unsorted;

  # TODO: Probably check for has_classes

  # ??? IS_WITHIN, IS_AROUND, MATCHES

  # Return 1 if frame definitions may result in unordered spans
  return 1 if $frames & $LEFT_FRAMES && $frames & $RIGHT_FRAMES;
};


1;


__END__

