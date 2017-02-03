package Krawfish::Query::Exclusion;
use parent 'Krawfish::Query::Base::Dual';
use Krawfish::Query::Base::Dual;
use Krawfish::Query::Position; # Export constants and @next_a and @next_b
use Krawfish::Query::Util::Bits; # exports bitstring
use Krawfish::Log;
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

use constant DEBUG => 0;

sub new {
  my $class = shift;
  bless {
    frames  => shift,
    first   => shift,
    second  => shift,
    buffer  => Krawfish::Query::Util::Buffer->new,
  }, $class;

  # TODO: Return 'first', if second->freq == 0
};


sub check {
  my $self = shift;
  my ($first, $second) = @_;

  # Create configuration debug message
  if (DEBUG) {
    my $str = "Configuration is $first";
    if ($second) {
      $str .= ' vs ' . $second;
    }
    else {
      $str .= ' only';
    };
    print_log('excl', $str);
  };

  # Get the current configuration
  my $case = Krawfish::Query::Position::case($first, $second);

  my $frames = $self->{frames};

  # There is a match - so A does not exclude B
  if ($case & $frames) {
    if (DEBUG) {
      print_log('excl', "Excluded span occurs - next with A");
      print_log('excl', '     for frames '.bitstring($frames));
      print_log('excl', '     with case  '.bitstring($case));
    };
    return NEXTA;
  };

  my $ret_val = NEXTA;

  # Span may forward with b
  if ($next_b[$case] & $frames) {
    $ret_val |= NEXTB;
  }

  # Span may forward with a
  elsif ($next_a[$case] & $frames) {
    print_log('excl', 'No next b valid - so match') if DEBUG;

    # Set current
    $self->{doc_id} = $first->doc_id;
    $self->{start}  = $first->start;
    $self->{end}    = $first->end;
    $self->{payload} = $first->payload->clone;
    print_log('excl', 'Set match to ' . $self->current->to_string) if DEBUG;

    # TODO:
    #   Forget all entries span_b in this frame, that have an spanb->end < spana->start
    # Hmmm ...
    return NEXTA | MATCH;
  }

  # No second span
  elsif (!$second) {
    print_log('excl', 'The case is null') if DEBUG;

    # Set current
    $self->{doc_id} = $first->doc_id;
    $self->{start}  = $first->start;
    $self->{end}    = $first->end;
    $self->{payload} = $first->payload->clone;
    print_log('excl', 'Set match to ' . $self->current->to_string) if DEBUG;
    return NEXTA | MATCH;
  };

  if (DEBUG) {
    print_log('excl', "Next frames are ".bitstring($next_a[$case])." for A and ");
    print_log('excl', '                '.bitstring($next_b[$case])." for B");
    print_log('excl', '     for frames '.bitstring($frames));
    print_log('excl', '     with case  '.bitstring($case));
  };

  return $ret_val;
};


sub to_string {
  my $self = shift;
  my $string = 'excl(' . (0 + $self->{frames}) . ':';
  $string .= $self->{first}->to_string . ',';
  return $string . $self->{second}->to_string . ')';
};


1;
