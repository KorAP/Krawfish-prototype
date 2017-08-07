package Krawfish::Koral::Corpus::Cache;
use parent 'Krawfish::Koral::Corpus';
use Krawfish::Corpus::Cache;
use strict;
use warnings;

use constant DEBUG => 0;

sub new {
  my $class = shift;
  bless {
    operands => [shift]
  }, $class;
};

sub type {
  'cache';
};


sub optimize {
  my ($self, $segment) = @_;

  my $query;
  unless ($query = $self->operand->optimize($segment)) {
    $self->copy_info_from($self->operand);
    return;
  };

  # Return cache
  return Krawfish::Corpus::Cache->new(
    $query,
    $segment->cache
  );
};


sub to_koral_fragment {
  return $_[0]->operand->to_koral_fragment;
};


sub to_string {
  return $_[0]->operand->to_string;
};


1;
