package Krawfish::Koral::Query::Match;
use Role::Tiny::With;
use Krawfish::Query::Match;
use Krawfish::Util::Bits;
use Krawfish::Util::Constants qw/:PAYLOAD/;
use strict;
use warnings;
use Krawfish::Koral::Query::Builder;

with 'Krawfish::Koral::Query';

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
#   This should be identical/similar to
#   Koral/Result/Match
sub to_koral_fragment {
  my $self = shift;
  my $mid = 'match:';

  $mid .= $self->operand->value;

  $mid .= '/p' . $self->{start} . '-' . $self->{end};

  # serialize classes
  if ($self->payload) {
    foreach ($self->payload->to_array) {
      # 0 is PTI_CLASS!
      $mid .= '_h';
      $mid .= '(' . $_->[1] . ')';
      $mid .= $_->[2] . '-' . $_->[3];
    };
  };

  foreach (flags_to_classes($self->flags)) {
    $mid .= '_c' . $_;
  };

  return {
    '@type' => 'koral:match',
    '@id' => $mid
  };
};


# Deserialization
sub from_koral {
  my ($class, $kq) = @_;

  my $match_id = $kq->{'@id'};

  # Work around
  my $qb = Krawfish::Koral::Query::Builder->new;

  # TODO:
  #   instead of match: also accept the match url
  #   from the context!
  if ($match_id =~ /^match:(.+?)\/p(\d+)-(\d+)((?:_h(?:\(\d+\))?\d+-\d+)*)((?:_c\d+)*)$/xo) {
    my $id = $1;
    my $start = $2;
    my $end = $3;
    my $highlights = $4;
    my $corpora = $5;

    my (@highlights, @corpora) = ();
    while ($highlights =~ /_h(?:\((\d+)\))?(\d+)-(\d+)/g) {
      push @highlights, [PTI_CLASS, $1 // 0, $2, $3];
    };

    while ($corpora =~ /\G_c(\d+)/g) {
      push @corpora, $1;
    };

    return $qb->match(
      $id, $start, $end, \@highlights, \@corpora
    );
  };

  return;
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
