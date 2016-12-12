package Krawfish::Koral::Corpus::Cache;
use parent 'Krawfish::Koral::Corpus';
use Krawfish::Corpus::Cache;
use strict;
use warnings;

use constant DEBUG => 0;

sub new {
  my $class = shift;
  bless {
    span => shift
  }, $class;
};

sub type {
  'cache';
};

sub plan_for {
  my ($self, $index) = @_;

  my $query;
  unless ($query = $self->{span}->plan_for($index)) {
    $self->copy_info_from($self->{span});
    return;
  };

  # Return cache
  return Krawfish::Corpus::Cache->new(
    $query,
    $index->cache
  );
};


sub to_koral_fragment {
  return $_[0]->{span}->to_koral_fragment;
};


sub to_string {
  return $_[0]->{span}->to_string;
};


1;
