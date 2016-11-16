package Krawfish::Query::Exclusion;
use parent 'Krawfish::Query::Position';
use Krawfish::Query::Base::Dual;
use Krawfish::Query::Position;
use strict;
use warnings;
use bytes;

# This query validates positional constraints
# that are exclusive returns a valid forwarding mechanism

# TODO:
# Exclude means e.g.
# "X is not in that positional relation with any Y",
# while the current solution only checks for
# "X is not in that positional relation with Y".
#
# The solution may be an exclusivity constraint,
# that may buffer valid X spans and release them once
# it's clear there is no Y in existence to be in the
# requested configuration.
# It's probably more like:
# excludeDouble(focus1:pos(![..], class(1:X), Y)
#
# Better: Use another query that also uses
# the check and is asymmetric, only returning the first
#
# Todo:
# span_a <- a is a candidate
# check, if a does not match.
# If a matches, go to next_a.
# If normal next_a is called,
# a is truely exclusive.


sub new {
  my $class = shift;
  bless {
    frames => shift,
    first => shift,
    second => shift,
    buffer  => Krawfish::Query::Util::Buffer->new,
  }, $class;
};

sub check {
  my $self = shift;
  my ($first, $second) = @_;

  # Get the current configuration
  my $case = case($first, $second);
  my $frames = $self->{frames};

  if ($case & $frames) {
    return NEXTA;
  }

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


sub to_string {
  my $self = shift;
  my $string = 'excl(' . (0 + $self->{frames}) . ':';
  $string .= $self->{first}->to_string . ',';
  return $string . $self->{second}->to_string . ')';
};


1;
