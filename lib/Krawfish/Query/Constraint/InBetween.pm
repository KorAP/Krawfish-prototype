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
  DEBUG => 0
};


sub new {
  my $class = shift;
  bless {
    min => shift,
    max => shift,
    foundry => shift,
    gaps => shift // 1
  }, $class;
};

sub to_string {
  my $self = shift;
  return 'dist=' . $self->{min} . '-' . $self->{max};
};

# Initialize foundry
sub _init {
  # If foundry is set, load token class and receive
  # max_subtokens
  ...
};

sub check {
  my $self = shift;
  my ($payload, $first, $second) = @_;

  # TODO:
  #   First check against max_tokens, so the real tokens
  #   are not consultated necessarily all the time

  # There are not enough segments to be valid
  return if $first->end - $second->start < $self->{min};

  if ($first->end == $second->start && $self->{min} == 0) {
    return NEXTA | NEXTB | MATCH | DONE;
  };

  # Check segments
  if (!$self->{foundry}) {
    ...
  }

  # Check tokens
  else {
    ...
  }
};

1;
