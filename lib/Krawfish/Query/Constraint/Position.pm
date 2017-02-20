package Krawfish::Query::Constraint::Position;
use parent 'Exporter';
use Krawfish::Log;
use Krawfish::Util::Bits; # exports bitstring()
use strict;
use warnings;

# This constraint validates positions
# between spans and returns a valid forwarding mechanism

use bytes;
use constant {
  NULL_4            => 0b0000_0000_0000_0000,
  PRECEDES          => 0b0000_0000_0000_0001,
  PRECEDES_DIRECTLY => 0b0000_0000_0000_0010,
  OVERLAPS_LEFT     => 0b0000_0000_0000_0100,
  ALIGNS_LEFT       => 0b0000_0000_0000_1000,
  STARTS_WITH       => 0b0000_0000_0001_0000,
  MATCHES           => 0b0000_0000_0010_0000,
  IS_WITHIN         => 0b0000_0000_0100_0000,
  IS_AROUND         => 0b0000_0000_1000_0000,
  ENDS_WITH         => 0b0000_0001_0000_0000,
  ALIGNS_RIGHT      => 0b0000_0010_0000_0000,
  OVERLAPS_RIGHT    => 0b0000_0100_0000_0000,
  SUCCEEDS_DIRECTLY => 0b0000_1000_0000_0000,
  SUCCEEDS          => 0b0001_0000_0000_0000,

  NEXTA => 1,
  NEXTB => 2,
  MATCH => 4,
  DEBUG => 0
};

our (@EXPORT, @next_a, @next_b);


sub new {
  my $class = shift;
  bless {
    frames => shift
  }, $class;
};


# In case of a configuration A,
# next_a may result in configuration B and
# next_b may result in configuration C
# These configurations were precomputed
$next_a[NULL_4] = NULL_4;
$next_b[NULL_4] = NULL_4;

$next_a[PRECEDES] =
  PRECEDES |
  PRECEDES_DIRECTLY |
  OVERLAPS_LEFT |
  ALIGNS_LEFT |
  STARTS_WITH |
  MATCHES |
  IS_AROUND |
  ENDS_WITH |
  ALIGNS_RIGHT |
  OVERLAPS_RIGHT |
  SUCCEEDS_DIRECTLY |
  SUCCEEDS;
$next_b[PRECEDES] =
  PRECEDES;

$next_a[PRECEDES_DIRECTLY] =
  PRECEDES |
  PRECEDES_DIRECTLY |
  OVERLAPS_LEFT |
  ALIGNS_LEFT |
  STARTS_WITH |
  MATCHES |
  IS_WITHIN |
  IS_AROUND |
  ENDS_WITH |
  ALIGNS_RIGHT |
  OVERLAPS_RIGHT |
  SUCCEEDS_DIRECTLY |
  SUCCEEDS;
$next_b[PRECEDES_DIRECTLY] =
  PRECEDES |
  PRECEDES_DIRECTLY;

$next_a[OVERLAPS_LEFT] =
  PRECEDES_DIRECTLY |
  OVERLAPS_LEFT |
  ALIGNS_LEFT |
  STARTS_WITH |
  MATCHES |
  IS_WITHIN |
  IS_AROUND |
  ENDS_WITH |
  ALIGNS_RIGHT |
  OVERLAPS_RIGHT |
  SUCCEEDS_DIRECTLY |
  SUCCEEDS;
$next_b[OVERLAPS_LEFT] =
  PRECEDES |
  PRECEDES_DIRECTLY |
  OVERLAPS_LEFT |
  IS_AROUND |
  ENDS_WITH;

$next_a[ALIGNS_LEFT] =
  ALIGNS_LEFT |
  STARTS_WITH |
  MATCHES |
  IS_WITHIN |
  ALIGNS_RIGHT |
  OVERLAPS_RIGHT |
  SUCCEEDS_DIRECTLY |
  SUCCEEDS;
$next_b[ALIGNS_LEFT] =
  PRECEDES |
  PRECEDES_DIRECTLY |
  OVERLAPS_LEFT |
  ALIGNS_LEFT |
  IS_AROUND |
  ENDS_WITH;

$next_a[STARTS_WITH] =
  STARTS_WITH |
  IS_WITHIN |
  ALIGNS_RIGHT |
  OVERLAPS_RIGHT |
  SUCCEEDS_DIRECTLY |
  SUCCEEDS;
$next_b[STARTS_WITH] =
  PRECEDES |
  PRECEDES_DIRECTLY |
  OVERLAPS_LEFT |
  ALIGNS_LEFT |
  STARTS_WITH |
  MATCHES |
  IS_AROUND |
  ENDS_WITH;

$next_a[MATCHES] =
  STARTS_WITH |
  MATCHES |
  IS_WITHIN |
  ALIGNS_RIGHT |
  OVERLAPS_RIGHT |
  SUCCEEDS_DIRECTLY |
  SUCCEEDS;
$next_b[MATCHES] =
  PRECEDES |
  PRECEDES_DIRECTLY |
  OVERLAPS_LEFT |
  ALIGNS_LEFT |
  MATCHES |
  IS_AROUND |
  ENDS_WITH;

$next_a[IS_WITHIN] =
  IS_WITHIN |
  ALIGNS_RIGHT |
  OVERLAPS_RIGHT |
  SUCCEEDS_DIRECTLY |
  SUCCEEDS;
$next_b[IS_WITHIN] =
  PRECEDES |
  PRECEDES_DIRECTLY |
  OVERLAPS_LEFT |
  ALIGNS_LEFT |
  STARTS_WITH |
  MATCHES |
  IS_WITHIN |
  ENDS_WITH |
  ALIGNS_RIGHT |
  OVERLAPS_RIGHT |
  SUCCEEDS_DIRECTLY;

$next_a[IS_AROUND] =
  PRECEDES_DIRECTLY |
  OVERLAPS_LEFT |
  ALIGNS_LEFT |
  STARTS_WITH |
  MATCHES |
  IS_AROUND |
  ENDS_WITH |
  ALIGNS_RIGHT |
  OVERLAPS_RIGHT |
  SUCCEEDS_DIRECTLY |
  SUCCEEDS;
$next_b[IS_AROUND] =
  PRECEDES |
  PRECEDES_DIRECTLY |
  OVERLAPS_LEFT |
  IS_AROUND |
  ENDS_WITH;

$next_a[ENDS_WITH] =
  PRECEDES_DIRECTLY |
  OVERLAPS_LEFT |
  ALIGNS_LEFT |
  STARTS_WITH |
  MATCHES |
  IS_WITHIN |
  IS_AROUND |
  ENDS_WITH |
  ALIGNS_RIGHT |
  OVERLAPS_RIGHT |
  SUCCEEDS_DIRECTLY |
  SUCCEEDS;
$next_b[ENDS_WITH] =
  PRECEDES |
  PRECEDES_DIRECTLY |
  OVERLAPS_LEFT |
  IS_AROUND |
  ENDS_WITH;

$next_a[ALIGNS_RIGHT] =
  IS_WITHIN |
  ALIGNS_RIGHT |
  OVERLAPS_RIGHT |
  SUCCEEDS_DIRECTLY |
  SUCCEEDS;
$next_b[ALIGNS_RIGHT] =
  PRECEDES |
  PRECEDES_DIRECTLY |
  OVERLAPS_LEFT |
  ALIGNS_LEFT |
  STARTS_WITH |
  MATCHES |
  IS_WITHIN |
  IS_AROUND |
  ENDS_WITH |
  ALIGNS_RIGHT |
  OVERLAPS_RIGHT |
  SUCCEEDS_DIRECTLY;

$next_a[OVERLAPS_RIGHT] =
  OVERLAPS_RIGHT |
  SUCCEEDS_DIRECTLY |
  SUCCEEDS;
$next_b[OVERLAPS_RIGHT] =
  PRECEDES |
  PRECEDES_DIRECTLY |
  OVERLAPS_LEFT |
  ALIGNS_LEFT |
  STARTS_WITH |
  MATCHES |
  IS_WITHIN |
  IS_AROUND |
  ENDS_WITH |
  ALIGNS_RIGHT |
  OVERLAPS_RIGHT |
  SUCCEEDS_DIRECTLY;

$next_a[SUCCEEDS_DIRECTLY] =
  SUCCEEDS_DIRECTLY |
  SUCCEEDS;
$next_b[SUCCEEDS_DIRECTLY] =
  PRECEDES |
  PRECEDES_DIRECTLY |
  OVERLAPS_LEFT |
  ALIGNS_LEFT |
  STARTS_WITH |
  MATCHES |
  IS_WITHIN |
  IS_AROUND |
  ENDS_WITH |
  ALIGNS_RIGHT |
  OVERLAPS_RIGHT |
  SUCCEEDS_DIRECTLY |
  SUCCEEDS;

$next_a[SUCCEEDS] =
  SUCCEEDS;
$next_b[SUCCEEDS] =
  PRECEDES |
  PRECEDES_DIRECTLY |
  OVERLAPS_LEFT |
  ALIGNS_LEFT |
  STARTS_WITH |
  MATCHES |
  IS_WITHIN |
  IS_AROUND |
  ENDS_WITH |
  ALIGNS_RIGHT |
  OVERLAPS_RIGHT |
  SUCCEEDS_DIRECTLY |
  SUCCEEDS;

@EXPORT = qw/NULL_4
             PRECEDES
             PRECEDES_DIRECTLY
             OVERLAPS_LEFT
             ALIGNS_LEFT
             STARTS_WITH
             MATCHES
             IS_WITHIN
             IS_AROUND
             ENDS_WITH
             ALIGNS_RIGHT
             OVERLAPS_RIGHT
             SUCCEEDS_DIRECTLY
             SUCCEEDS
             @next_a
             @next_b/;


# Check the configuration
sub check {
  my $self = shift;
  my ($first, $second) = @_;

  # Get the current configuration
  my $case = case($first, $second);
  my $frames = $self->{frames};

  print_log('posC', "The case is     " . bitstring($case)   . " ($case)") if DEBUG;
  print_log('posC', "for the frames  " . bitstring($frames) . " ($frames)") if DEBUG;

  # Configuration is valid
  if ($case & $frames) {

    print_log('posC', 'There is a match') if DEBUG;
    return NEXTA | NEXTB | MATCH;
  };

  # Initialize the return value
  my $ret_val = 0b0000;

  # Span may forward with a
  if ($next_a[$case] & $frames) {
    $ret_val |= NEXTA
  };

  # Span may forward with b
  if ($next_b[$case] & $frames) {
    $ret_val |= NEXTB
  };

  if (DEBUG) {
    print_log('posC', "Next frames are ".bitstring($next_a[$case])." and ");
    print_log('posC', '                '.bitstring($next_b[$case]));
  };
  return $ret_val;
};



# Return the current configuration
sub case {
  my $span_a = shift;
  my $span_b = shift;

  return NULL_4 if !$span_a || !$span_b;


  # A starts after B
  # [b..[a..
  if ($span_a->start > $span_b->start) {

    # Don't call end() on A
    # [b..][a..]
    if ($span_a->start == $span_b->end) {
      return SUCCEEDS_DIRECTLY;
    }

    # [b..]..[a..]
    elsif ($span_a->start > $span_b->end) {
      return SUCCEEDS;
    }

    # [b..[a..]]
    elsif ($span_a->end == $span_b->end) {
      return ALIGNS_RIGHT;
    }

    # [b..[a..]..]
    elsif ($span_a->end < $span_b->end) {
      return IS_WITHIN;
    };

    # $span_a->end > $span_b->end &&
    # $span_a->start < $span_b->end
    # [b..[a..b]..a]
    return OVERLAPS_RIGHT;
  }

  # A starts before B
  # [a..[b..
  elsif ($span_a->start < $span_b->start) {

    # Don't call end() on b
    # [a..][b..]
    if ($span_a->end == $span_b->start) {
      return PRECEDES_DIRECTLY;
    }

    # [a..]..[b..]
    elsif ($span_a->end < $span_b->start) {
      return PRECEDES;
    }

    # Call end() on B
    # [a..[b..]]
    elsif ($span_a->end == $span_b->end) {
      return ENDS_WITH;
    }

    # [a..[b..]..]
    elsif ($span_a->end > $span_b->end) {
      return IS_AROUND;
    };

    # $span_a->end > $span_b->start
    # [a..[b..a]..b]
    return OVERLAPS_LEFT;
  }

  # A and B start at the same position
  # $span_a->start == $span_b->start
  # [a[b ..] ..]
  elsif ($span_a->end > $span_b->end) {
    return STARTS_WITH;
  }

  # [a[b..a]..b]
  # $span_a->start == $span_b->start
  elsif ($span_a->end < $span_b->end) {
    return ALIGNS_LEFT;
  };

  # $span_a->end == $span_b->end
  # [a[b..b]a]
  return MATCHES;
};


sub to_string {
  'pos=' . (0 + $_[0]->{frames});
};

1;
