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

sub new {
  my $class = shift;
  bless {
    foundry => shift,
    min => shift,
    max => shift,
    gaps => shift // 1
  }, $class;
};


sub check {
  my $self = shift;
  my ($payload, $first, $second) = @_;

  # There are not enough segments to be valid
  return if $first->end - $second->start < $self->{min};

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
