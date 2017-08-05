package Krawfish::Koral::Query::Match;
use parent 'Krawfish::Koral::Query';
use Krawfish::Query::Match;
use strict;
use warnings;

# This Query does not search segment data, but
# returns the data it is passed to.
# It is used to fetch enriched match data.
# Normally it only matches for certain documents,
# meaning it is normally encapsulated into a filter.

use constant {
  DEBUG => 0
};


sub new {
  my $class = shift;
  bless {
    operands => [shift],
    start    => shift,
    end      => shift
  }, $class;
};


sub to_koral_fragment {
  my $self = shift;
  return {
    '@type' => 'koral:match',
    'doc' => $self->operand->to_koral_fragment,
    'start' => $self->start,
    'end' => $self->end
  };
};

sub type { 'match' };


# A match has a defined span
sub min_span {
  $_[0]->end - $_[0]->start;
};


# A match has a defined span
sub max_span {
  $_[0]->end - $_[0]->start;
};


# Normalize the class query
sub normalize {
  my $self = shift;

  my $doc;
  unless ($doc = $self->operand->normalize) {
    $self->copy_info_from($self->operand);
    return;
  };

  $self->operand($doc);

  # If there can't be a valid match
  if ($self->start < 0) {

    # TODO:
    #   Warn about out of scope
    return $self->builder->nothing;
  }

  # Defined span is negative
  elsif ($self->start > $self->end) {
    return $self->builder->nothing;
  };

  return $self;
};


# Treat the query as if it is root
sub finalize {
  my $self = shift;

  # If there can't be a valid match
  if ($self->start == $self->end) {
    return $self->builder->nothing;
  };

  return $self;
};


# Optimize on index
sub optimize {
  my ($self, $segment) = @_;

  # Get document optimized
  my $doc = $self->operand->optimize($segment);

  # Return nothing if document is not found
  return $doc if $doc->max_freq == 0;

  return Krawfish::Query::Match->new(
    $doc,
    $self->start,
    $self->end
  );
};



sub to_string {
  my $self = shift;
  return '[[' . $self->operand->to_string . ':' . $self->start . '-' . $self->end . ']]';
};


sub start {
  $_[0]->{start};
};


sub end {
  $_[0]->{end};
};


sub is_any {
  0;
};


sub is_optional {
  0;
};


sub is_null {
  my $self = shift;
  if ($self->start == $self->end) {
    return 1;
  };
  return;
};


sub is_negative {
  0;
};


sub is_extended {
  1;
};


sub is_extended_right {
  1;
};


sub is_extended_left {
  0;
};


sub maybe_unsorded {
  0;
};


sub is_classed {
  0;
};


sub from_koral {
  my ($class, $kq) = @_;
  ...
};


1;
