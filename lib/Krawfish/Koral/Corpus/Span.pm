package Krawfish::Koral::Corpus::Span;
use Role::Tiny::With;
use Krawfish::Util::Constants ':PREFIX';
use Krawfish::Query::Nowhere;
use Krawfish::Corpus::Span;
use Krawfish::Log;
use strict;
use warnings;

with 'Krawfish::Koral::Corpus';

# This VC criterion takes a query and checks for existence (or occurrence) in texts

use constant DEBUG => 0;

sub new {
  my $class = shift;
  bless {
    operands => [shift],
    min => (shift // 1),
    max => shift
  }, $class;
};


# Query type
sub type {
  'corpusSpan';
};


# Toggle negativity if required
sub toggle_negativity {
  ...
};


# Span query is not a leaf
sub is_leaf { 0 };


# Normalize query
sub normalize {
  my $self = shift;

  # TODO:
  #   This could be normalized to optimize, in case the embedded query
  #   is a single token. Then the number of tokens per text can be checked instead
  #   of the occurrences.

  if (DEBUG) {
    print_log('kq_c_span', 'Normalize span query');
    print_log('kq_c_span', 'Remove classes from ' . $self->operand->to_string);
  };

  # Remove classes from operand (they can't be used)
  my $span = $self->operand->remove_classes;

  if (DEBUG) {
    print_log('kq_c_span', 'Span without classes is ' . $span->to_string);
  };


  # Normalize operand
  my $norm;
  unless ($norm = $span->normalize) {

    $self->copy_info_from($span);
    return;
  };

  # Deal with anywhere spans
  if ($norm->is_anywhere || $norm->is_optional || $norm->is_null) {
    return $norm->builder->anywhere;
  };

  if ($self->{min} == 0) {
    if (!defined $self->{max} || $self->{max} == 0) {
      return $self->builder->anywhere;
    }
    else {
      return $self->builder->bool_and_not(
        $self->builder->anywhere,
        $self->builder->span(
          $norm,
          $self->{max} + 1
        )
      )->normalize;
    }
  };

  # Finalize span query to ensure,
  # There is no invalid extension
  my $final;
  unless ($final = $norm->finalize) {

    $self->copy_info_from($norm);
    return;
  };

  # Set operand
  $self->operand($final);

  if (DEBUG) {
    print_log('kq_c_span', 'Normalized operand is ' . $final->to_string);
  };

  return $self;
};


# Optimize query
sub optimize {
  my ($self, $segment) = @_;

  if (DEBUG) {
    print_log('kq_c_span', 'Plan span corpus query');
  };

  # Optimize span against segment
  my $span = $self->operand->optimize($segment);

  # Can't match anywhere
  if ($span->max_freq == 0) {
    return Krawfish::Query::Nowhere->new;
  };

  # Return span query
  return Krawfish::Corpus::Span->new(
    $span,
    $self->{min},
    $self->{max}
  );
};


# The span query can't have classes
sub has_classes {
  0;
};


# Check for negativity
sub is_negative {
  $_[0]->operand->is_negative;
};


# Toggle negativity
sub toggle_negative {
  ...
};


# Check if the query matches anywhere
sub is_anywhere {
  $_[0]->operand->is_anywhere
};


# Check if the query matches nowhere
sub is_nowhere {
  $_[0]->operand->is_nowhere
};


# Check if thew query is neglectable
sub is_null {
  $_[0]->operand->is_null;
};


# Stringify
sub to_string {
  my ($self, $id) = @_;
  my $str = 'span(' . $self->operand->to_string($id);
  if ($self->{min} != 1 || defined $self->{max}) {
    $str .= ',' . $self->{min};
    $str .= ',' . $self->{max} if $self->{max};
  };
  return $str . ')';
};


sub to_sort_string {
  my $self = shift;
  my $str = 'span(' . $self->operand->to_sort_string;
  if ($self->{min} != 1 || defined $self->{max}) {
    $str .= ',' . $self->{min};
    $str .= ',' . $self->{max} if $self->{max};
  };
  return $str . ')';
};

# Serialize to KoralQuery
sub to_koral_fragment {
  my $self = shift;
  my $obj = {
    '@type' => 'koral:query',
    'span' => $self->operand->to_koral_fragment
  };
  if ($self->{min} != 1) {
    $obj->{min} = $self->{min};
  };
  if (defined $self->{max}) {
    $obj->{max} = $self->{max};
  };
  return $obj;
};


sub from_koral {
  ...
};

1;

__END__

