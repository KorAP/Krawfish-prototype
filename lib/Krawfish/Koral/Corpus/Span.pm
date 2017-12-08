package Krawfish::Koral::Corpus::Span;
use Role::Tiny::With;
use Krawfish::Util::Constants ':PREFIX';
use Krawfish::Query::Nowhere;
use Krawfish::Corpus::Span;
use Krawfish::Log;
use strict;
use warnings;

with 'Krawfish::Koral::Corpus';

use constant DEBUG => 0;

sub new {
  my $class = shift;
  bless {
    operands => [shift]
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

  if (DEBUG) {
    print_log('kq_c_span', 'Normalize span query');
    print_log('kq_c_span', 'Remove classes from ' . $self->operand->to_string);
  };

  # Remove classes from operand (the can't be used)
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
    $span
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
  my $self = shift;
  return 'span(' . $self->operand->to_string . ')'
};


# Serialize to KoralQuery
sub to_koral_fragment {
  my $self = shift;
  return {
    '@type' => 'koral:query',
    'span' => $self->operand->to_koral_fragment
  }
};


sub from_koral {
  ...
};

1;

__END__

