package Krawfish::Koral::Query::InCorpus;
use Role::Tiny::With;
use Krawfish::Util::Bits;
use Krawfish::Query::InCorpus;
use strict;
use warnings;

with 'Krawfish::Koral::Query::Proxy';
with 'Krawfish::Koral::Query';

# Create a query that will check if a certain
# match is associated to certain corpus classes.

# Accepts the nesting query and a number of valid
# corpus classes.

# This will, by default, form an or-relation regarding
# the given classes. To form an and-relation, multiple
# incorpus queries need to be nested.

# TODO:
#   Improve normalization!
#   In case the operand is an incorpus query as well,
#   check for identical classes.
#     incorpus(3,4:incorpus(2,3,4:...))
#   is identical to
#     incorpus(2,3,4:...))
#   but
#     incorpus(2:incorpus(3:...))
#   is NOT identical to
#     incorpus(2,3:...)

# Constructor
sub new {
  my $class = shift;
  bless {
    operands => [shift],
    corpus_classes => [@_]
  }, $class;
};


# Query type
sub type { 'incorpus' };


# Normalize unique query
sub normalize {
  my $self = shift;

  my $span;
  unless ($span = $self->operand->normalize) {
    $self->copy_info_from($self->operand);
    return;
  };

  $self->operands([$span]);

  return $self;
};


# Optimize query to potentially need sorting
sub optimize {
  my ($self, $segment) = @_;

  my $span;

  # Not plannable
  unless ($span = $self->operand->optimize($segment)) {
    $self->copy_info_from($self->span);
    return;
  };

  # Span has no match
  if ($span->max_freq == 0) {
    return $self->builder->nowhere;
  };

  return Krawfish::Query::InCorpus->new(
    $span,
    classes_to_flags(@{$self->{corpus_classes}})
  );
};


# Stringification
sub to_string {
  my $self = shift;
  return 'inCorpus(' . join(',',@{$self->{corpus_classes}}) . ':' .
    $self->operand->to_string . ')';
};


# Serialization to KQ
sub to_koral_fragment {
  ...
};


sub from_koral {
  ...
};


1;
