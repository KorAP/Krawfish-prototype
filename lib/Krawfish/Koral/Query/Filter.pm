package Krawfish::Koral::Query::Filter;
use parent 'Krawfish::Koral::Query';
use Krawfish::Query::Nothing;
use strict;
use warnings;

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

use constant DEBUG => 1;

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
  my ($self, $index) = @_;

  # Optimize corpus
  my $corpus = $self->corpus->optimize($index);

  # Filter would rule out everything
  if ($corpus->max_freq == 0) {
    return Krawfish::Query::Nothing->new;
  };

  # Optimize span
  my $span = $self->operand->optimize($index);

  # Filter would rule out everything
  if ($span->max_freq == 0) {
    return Krawfish::Query::Nothing->new;
  };

  # Filter the span with the corpus
  return $span->filter_by($corpus);
};


sub corpus {
  $_[0]->{corpus};
};


sub to_string {
  my $self = shift;
  my $str = 'filter(';
  $str .= $self->operand->to_string;
  $str .= ',';
  $str .= $self->corpus->to_string;
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


1;


__END__
