package Krawfish::Query::Constraints;
use parent 'Krawfish::Query::Base::Dual';
use Krawfish::Util::Buffer;
use List::Util qw/min/;
use Krawfish::Log;
use strict;
use warnings;

# TODO:
#   Improve by skipping to the same document
#
# TODO:
#   The check probably needs more than just the span
#   information, e.g. to get the max_length() of
#   a span for skip_pos() stuff.

use constant {
  NEXTA => 1,
  NEXTB => 2,
  MATCH => 4,
  DONE  => 8, # Short circuit match
  DEBUG => 0
};


# Constructor
sub new {
  my $class = shift;
  bless {
    constraints => shift,
    first => shift,
    second => shift,

    # TODO:
    #   Second operand should be nested
    #   in buffer by Dual
    buffer  => Krawfish::Util::Buffer->new
  }, $class;
};


# Clone query
sub clone {
  my $self = shift;
  __PACKAGE__->new(
    [map { $_->clone } @{$self->{constraints}}],
    $self->{first}->clone,
    $self->{second}->clone
  );
};


# Check all constraints sequentially
sub check {
  my $self = shift;
  my ($first, $second) = @_;

  # Initialize the return value
  my $ret_val = 0b0111;

  # Iterate
  foreach (@{$self->{constraints}}) {

    # TODO:
    #   Under certain circumstances it may be
    #   faster to

    # Check constrained
    my $check = $_->check($first, $second);

    # Combine NEXTA and NEXTB rules
    $ret_val &= $check;

    # Check matches
    unless ($check & MATCH) {

      if (DEBUG) {
        print_log('constr', 'Constraint ' . $_->to_string . ' does not match');
      };

      # No match - send NEXTA and NEXTB rules
      return $ret_val;
    };

    if (DEBUG) {
      print_log('constr', 'Constraint ' . $_->to_string . ' matches for ' .
                  $first->to_string . ' and ' . $second->to_string);
    };

    # If done flag is set, do short circuit
    last if $check & DONE;
  };

  # Match!
  $self->{doc_id}  = $first->doc_id;

  # Flags need to be considered from both operands,
  # as not both operands are filtered
  $self->{flags}   = $first->flags | $second->flags;
  $self->{start}   = $first->start < $second->start ? $first->start : $second->start;
  $self->{end}     = $first->end > $second->end ? $first->end : $second->end;
  $self->{payload} = $first->payload->clone->copy_from($second->payload);

  print_log('constr', 'Constraint matches: ' . $self->current->to_string) if DEBUG;

  return $ret_val | MATCH;
};


# Get maximum frequency of query
sub max_freq {
  my $self = shift;
  min($self->{first}->max_freq, $self->{second}->max_freq);
};


# Filter constraint by a corpus by only applying to
# the least frequent operand, in case, there are no
# further requirements
sub filter_by {
  my ($self, $corpus) = @_;

  my $first = $self->{first};
  my $second = $self->{second};

  # There is a need for filtering
  if ($first->requires_filter || $second->requires_filter) {

    # First operand requires a filter
    if ($first->requires_filter) {
      $self->{first} = $first->filter_by($corpus);
    };

    # Second operand requires a filter
    if ($second->requires_filter) {
      $self->{second} = $second->filter_by($corpus);
    };

    return $self;
  };

  # The first operand is least frequent
  if ($first->max_freq < $second->max_freq) {
    $self->{first} = $first->filter_by($corpus);
  }

  # The second operand is least frequent (default)
  else {
    $self->{second} = $second->filter_by($corpus);
  };
  return $self;
};


# Requires filtering
sub requires_filter {
  my $self = shift;
  if ($self->{first}->requires_filter) {
    return 1;
  }
  elsif ($self->{second}->requires_filter) {
    return 1;
  };
  return 0;
};


# Stringification
sub to_string {
  my $self = shift;
  my $str = 'constr(';
  $str .= join(',', map { $_->to_string } @{$self->{constraints}});
  $str .= ':';
  $str .= $self->{first}->to_string . ',' . $self->{second}->to_string;
  return $str . ')';
};


1;
