package Krawfish::Koral::Corpus::Cache;
use parent 'Krawfish::Koral::Corpus';
use Krawfish::Corpus::Cache;
use strict;
use warnings;

use constant DEBUG => 0;

sub new {
  my $class = shift;
  bless {
    corpus => shift
  }, $class;
};

sub type {
  'cache';
};


sub optimize {
  my ($self, $index) = @_;

  my $query;
  unless ($query = $self->{corpus}->plan_for($index)) {
    $self->copy_info_from($self->{corpus});
    return;
  };

  # Return cache
  return Krawfish::Corpus::Cache->new(
    $query,
    $index->cache
  );
};


sub to_koral_fragment {
  return $_[0]->{corpus}->to_koral_fragment;
};


sub to_string {
  return $_[0]->{corpus}->to_string;
};


1;
