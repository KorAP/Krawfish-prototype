package Krawfish::Query::Constraint::InBetween;
use strict;
use warnings;

# Check tokens or segments in between.
# Like [orth=Der][]{1,2}[orth=Mann] or
# [orth=Der][opennlp]{1,2}[orth=Mann].

# There is a special behaviour, called "gaps":
# If gaps is true, the operands may have a different
# tokenization and do not necessarily match with the tokenization for
# the inbetweens.
#
# Example:
# [orth=Der][opennlp]{2,3}[orth=Mann]
# To not allow gaps, use
# [orth=Der][opennlp]{!2,3}[orth=Mann]


# TODO: Order may not be defined!

# TODO:
#   If min=0, a shortcircuit result is returned and following
#   constraints are ignored

use constant {
  NEXTA => 1,
  NEXTB => 2,
  MATCH => 4,
  DONE  => 8, # Short circuit match
  ALL_MATCH => (1 | 2 | 4),
  DEBUG => 0
};


# Constructor
sub new {
  my $class = shift;
  bless {
    min => shift,
    max => shift,
    foundry => shift,
    gaps => shift // 1
  }, $class;
};


# Initialize foundry
sub init {
  # If foundry is set, load token class and receive
  # max_subtokens
  ...
};


# Check the distance
sub check {
  my $self = shift;
  my ($first, $second, $payload) = @_;

  # Order operands
  if ($first->end > $second->start) {
    my $temp = $second;
    $second = $first;
    $first = $temp;
  };

  # TODO:
  #   First check against max_tokens, so the real tokens
  #   are not consultated necessarily all the time

  # Check segments
  # if (!$self->{foundry}) {
  #   ...
  # }

  # Check tokens
  # else {
  #   ...
  # }

  if (!$first || !$second) {
    return NEXTA | NEXTB;
  };

  # Fine and disable following constraints
  if ($self->{min} == 0 && $first->end == $second->start) {
    return ALL_MATCH | DONE;
  };

  # There are not enough segments to be valid
  if (($second->start - $first->end) < $self->{min} or
        (defined $self->{max} && ($second->start - $first->end) > $self->{max})) {
    return NEXTA | NEXTB;
  };

  return ALL_MATCH;
};


# Stringification
sub to_string {
  my $self = shift;
  return 'between=' . $self->{min} . '-' . (defined $self->{max} ? $self->{max} : 'INF');
};


1;


__END__
