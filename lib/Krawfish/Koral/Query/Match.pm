package Krawfish::Koral::Query::Match;
use Role::Tiny::With;
use Krawfish::Query::Match;
use Krawfish::Util::Bits;
use strict;
use warnings;

with 'Krawfish::Koral::Query';


# TODO:
#   Suport corpus classes!

# TODO:
#   Support highlights!

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
    end      => shift,
    payload  => shift,
    flags    => shift
  }, $class;
};


# Payloads
sub payload {
  return $_[0]->{payload};
};


# Flags
sub flags {
  return $_[0]->{flags};
};


# Serialization
sub to_koral_fragment {
  my $self = shift;
  my $kq = {
    '@type' => 'koral:match',
    'doc' => $self->operand->to_koral_fragment,
    'start' => $self->start,
    'end' => $self->end
  };

  # serialize classes
  if ($self->payloads) {
    # $obj->{payload} = $self->payload->to_array;
  };

  # serialize flags
  if ($self->flags) {
    $kq->{corpusClasses} = [flags_to_classes($self->flags)];
  };

  return $kq;
};


# Deserialization
sub from_koral {
  my ($class, $kq) = @_;

  my $importer = $class->importer;

  
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
    return $self->builder->nowhere;
  }

  # Defined span is negative
  elsif ($self->start > $self->end) {
    return $self->builder->nowhere;
  };

  return $self;
};


# Treat the query as if it is root
sub finalize {
  my $self = shift;

  # If there can't be a valid match
  if ($self->start == $self->end) {
    return $self->builder->nowhere;
  };

  return $self;
};


# Optimize on segment
sub optimize {
  my ($self, $segment) = @_;

  # Get document optimized
  my $doc = $self->operand->optimize($segment);

  # Return nowhere if document is not found
  return $doc if $doc->max_freq == 0;

  return Krawfish::Query::Match->new(
    $doc,
    $self->start,
    $self->end,
    $self->payload,
    $self->flags
  );
};



sub to_string {
  my $self = shift;
  my $str = '[[' . $self->operand->to_string . ':' . $self->start . '-' . $self->end;

  # In case a class != 0 is set - serialize
  if ($self->flags && $self->flags & 0b0111_1111_1111_1111) {
    $str .= '!' . join(',', flags_to_classes($self->{flags}));
  };

  $str .= '$' . $self->payload->to_string if $self->payload;

  return $str . ']]';
};


sub start {
  $_[0]->{start};
};


sub end {
  $_[0]->{end};
};


sub is_anywhere {
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


1;
