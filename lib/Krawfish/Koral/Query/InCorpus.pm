package Krawfish::Koral::Query::InCorpus;
use parent 'Krawfish::Koral::Query';
use Krawfish::Util::Bits;
use Krawfish::Query::InCorpus;
use strict;
use warnings;

# Create a query that will check if a certain
# match is associated to certain classes.

# Accepts the nesting query and a number of valid
# corpus classes

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
  return 'inCorpus(' . join(',',@{$self->{corpus_classes}}) . ':' . $self->operand->to_string . ')';
};


# Serialization to KQ
sub to_koral_fragment {
  ...
};


# TODO: Identical to class/unique

sub is_anywhere {
  $_[0]->operand->is_anywhere;
};


sub is_optional {
  $_[0]->operand->is_optional;
};


sub is_null {
  $_[0]->operand->is_null;
};


sub is_negative {
  $_[0]->operand->is_negative;
};


sub is_extended {
  $_[0]->operand->is_extended;
};


sub is_extended_right {
  $_[0]->operand->is_extended_right;
};


sub is_extended_left {
  $_[0]->operand->is_extended_left;
};


sub is_classed {
  $_[0]->operand->is_classed;
};


sub maybe_unsorted {
  $_[0]->operand->maybe_unsorted;
};


# A unique query always spans its operand span
sub min_span {
  $_[0]->operand->min_span;
};


# A unique query always spans its operand span
sub max_span {
  $_[0]->operand->max_span;
};


1;
