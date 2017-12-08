package Krawfish::Koral::Query::Filter;
use Role::Tiny::With;
use Krawfish::Log;
use Krawfish::Query::Nowhere;
use strict;
use warnings;
use Memoize;
memoize('min_span');
memoize('max_span');

with 'Krawfish::Koral::Query';

# The filter will filter a query based on a virtual corpus.
# First the filter is always on the root of the query.
#
# filter(author=goethe,[Der][alte&ADJ][Mann])
#
# In the normalization phase, this will probably not change
# much.
#
# In the optimization phase, in queries where ordering is key
# (like and-queries), the filter will be adopted to the rarest
# operand.
#
# next([Der],previous(filter(author=goethe,[Mann]),[alte&ADJ]))

use constant DEBUG => 0;

sub new {
  my $class = shift;
  bless {
    operands => [shift],
    corpus => shift
  }, $class;
};


# Query type
sub type { 'filter' };


# Normalize query
sub normalize {
  my $self = shift;

  # Normalize the span
  my $span;
  unless ($span = $self->operand->normalize) {
    $self->copy_info_from($self->operand);
    return;
  };

  # Normalize the corpus
  my $corpus;
  unless ($corpus = $self->corpus->normalize) {
    $self->copy_info_from($self->corpus);
    return;
  };

  $self->operand($span);
  return $self;
};


# Todo: Handle zero results!
sub identify {
  my ($self, $dict) = @_;

  my $ops = $self->operands;

  $ops->[0] = $ops->[0]->identify($dict);

  if ($ops->[0]->is_nowhere) {
    return $ops->[0];
  };

  $self->{corpus} = $self->{corpus}->identify($dict);

  # Matches nowhere
  if ($self->{corpus}->is_nowhere) {
    return $self->{corpus};
  };

  return $self;
};


# Finalize the wrapped span
sub finalize {
  my $self = shift;

  # Finalize the span
  my $span;
  unless ($span = $self->operand->finalize) {
    $self->copy_info_from($self->operand);
    return;
  };

  $self->operand($span);
  return $self;
};


sub optimize {
  my ($self, $segment) = @_;

  if (DEBUG) {
    print_log('kq_filter', 'Optimize filter ' . $self->to_string);
  };

  # Optimize corpus
  my $corpus = $self->corpus->optimize($segment);

  # Filter would rule out everything
  if ($corpus->max_freq == 0) {

    if (DEBUG) {
      print_log('kq_filter', 'Corpus ' . $self->corpus->to_string . ' is empty');
    };
    return Krawfish::Query::Nowhere->new;
  };

  # Optimize span
  my $span = $self->operand->optimize($segment);

  if (DEBUG) {
    print_log('kq_filter', 'Operands are now ' .
                ref($span) . ':' . $span->to_string . ' and ' .
                ref($corpus) . ':' . $corpus->to_string);
  };

  # Filter would rule out everything
  if ($span->max_freq == 0) {
    return Krawfish::Query::Nowhere->new;
  };

  # Filter the span with the corpus
  my $filter =  $span->filter_by($corpus);

  if (DEBUG) {
    print_log(
      'kq_filter',
      'Optimized filter query is ' . ref($filter) . ':' . $filter->to_string
    );
  };

  return $filter;
};


sub corpus {
  $_[0]->{corpus};
};


sub to_string {
  my ($self, $id) = @_;
  my $str = 'filter(';
  $str .= $self->operand->to_string($id);
  $str .= ',';
  $str .= $self->corpus->to_string($id);
  return $str . ')';
};


sub to_koral_fragment {
  my $self = shift;
  return {
    '@type' => 'koral:filter',
    'span' => $self->operand->to_koral_fragment,
    'corpus' => $self->corpus->to_koral_fragment
  };
};


sub from_koral {
  ...
};


# Return the minimum numbers of tokens of the span
sub min_span {
  $_[0]->operand->min_span;
};


# Return the maximum numbers of tokens of the span
sub max_span {
  $_[0]->operand->max_span;
};


1;


__END__
