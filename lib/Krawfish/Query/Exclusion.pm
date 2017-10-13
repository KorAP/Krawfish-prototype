package Krawfish::Query::Exclusion;
use parent 'Krawfish::Query::Base::Dual';
use Krawfish::Query::Base::Dual;
use Krawfish::Query::Constraint::Position; # Export constants and @next_a and @next_b
use Krawfish::Util::Bits; # exports bitstring
use Krawfish::Log;
use strict;
use warnings;
use bytes;

# This query validates positional constraints
# that are exclusive returns a valid forwarding mechanism

# It checks for an operand X that there is no operand Y
# in the given positional relation

use constant DEBUG => 0;


# Constructor
sub new {
  my $class = shift;
  bless {
    frames  => shift,
    first   => shift,
    second  => shift,
    buffer  => Krawfish::Util::Buffer->new,
  }, $class;
};


# Clone query
sub clone {
  my $self = shift;
  __PACKAGE__->new(
    $self->{frames},
    $self->{first}->clone,
    $self->{second}->clone
  );
};


# Check for configuration
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
  my $case = Krawfish::Query::Constraint::Position::case($first, $second);

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
    #   by returning a value that triggers skip_pos()

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


# Stringification
sub to_string {
  my $self = shift;
  my $string = 'excl(' . (0 + $self->{frames}) . ':';
  $string .= $self->{first}->to_string . ',';
  return $string . $self->{second}->to_string . ')';
};


# Get maximum frequency
sub max_freq {
  $_[0]->{first}->max_freq;
};


# Filter query by a VC
sub filter_by {
  my ($self, $corpus) = @_;

  # Only the first operand is relevant
  $self->{first} = $self->{first}->filter_by($corpus);
  return $self;
};


1;
