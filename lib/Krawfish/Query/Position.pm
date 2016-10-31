package Krawfish::Query::Position;
use parent 'Krawfish::Query::Base::Dual';
use Krawfish::Query::Base::Dual;
use strict;
use warnings;

# This query validates positional constraints
# between spans and returns a valid forwarding mechanism

# http://www.perlmonks.org/?node_id=512743
# TODO: Should be inherited
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
  SUCCEEDS          => 0b0001_0000_0000_0000
};

our (@EXPORT, @next_a, @next_b);
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
             SUCCEEDS/;

sub new {
  my $class = shift;
  bless {
    frames => shift,
    first => shift,
    second => shift,
    buffer  => Krawfish::Query::Util::Buffer->new,
  }, $class;
};


# Check the configuration
sub check {
  my $self = shift;
  my ($first, $second) = @_;

  # Get the current configuration
  my $case = case($first, $second);
  my $frames = $self->{frames};

  print "  >> The case is    " ._bits($case)  . " ($case)\n";
  print "     for the frames " ._bits($frames) . " ($frames)\n";

  # Configuration is valid
  if ($case & $frames) {

    # Set current
    $self->{doc} = $first->doc;
    $self->{start} = $first->start < $second->start ? $first->start : $second->start;
    $self->{end}   = $first->end > $second->end ? $first->end : $second->end;

    print "  >>There is a match - make current match: " . $self->current . "\n";
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

  print "  >> Next frames are "._bits($next_a[$case])." and "._bits($next_b[$case])."\n";
  return $ret_val;
};


sub _bits ($) {
  return unpack "b16", pack "s", shift;
};

# In case of a configuration A,
# next_a may result in configuration B and
# next_b may result in configuration C
# These configurations were precomputed
$next_a[PRECEDES] = 
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
$next_b[PRECEDES] = 
  PRECEDES;

$next_a[PRECEDES_DIRECTLY] = 
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
  OVERLAPS_LEFT;

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
  ALIGNS_LEFT;

$next_a[STARTS_WITH] = 
  STARTS_WITH |
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
  ALIGNS_LEFT |
  IS_WITHIN;

$next_a[IS_AROUND] = 
  STARTS_WITH |
  IS_AROUND |
  SUCCEEDS_DIRECTLY |
  SUCCEEDS;
$next_b[IS_AROUND] = 
  PRECEDES |
  PRECEDES_DIRECTLY |
  OVERLAPS_LEFT |
  IS_AROUND |
  ENDS_WITH;

$next_a[ENDS_WITH] = 
  STARTS_WITH |
  MATCHES |
  IS_AROUND |
  ENDS_WITH |
  SUCCEEDS_DIRECTLY |
  SUCCEEDS;
$next_b[ENDS_WITH] = 
  PRECEDES |
  PRECEDES_DIRECTLY |
  OVERLAPS_LEFT |
  ENDS_WITH;

$next_a[ALIGNS_RIGHT] = 
  ALIGNS_RIGHT |
  OVERLAPS_RIGHT |
  SUCCEEDS_DIRECTLY |
  SUCCEEDS;
$next_b[ALIGNS_RIGHT] = 
  PRECEDES |
  PRECEDES_DIRECTLY |
  ALIGNS_LEFT |
  MATCHES |
  IS_WITHIN |
  ALIGNS_RIGHT;

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
  OVERLAPS_RIGHT;

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
  SUCCEEDS_DIRECTLY;

$next_a[SUCCEEDS] = 
  SUCCEEDS;
$next_b[SUCCEEDS] = 
  PRECEDES |
  PRECEDES_DIRECTLY |
  ALIGNS_LEFT |
  STARTS_WITH |
  MATCHES |
  IS_WITHIN |
  ALIGNS_RIGHT |
  SUCCEEDS_DIRECTLY |
  SUCCEEDS;


# Return the current configuration
sub case {
  my $span_a = shift;
  my $span_b = shift;

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


1;
