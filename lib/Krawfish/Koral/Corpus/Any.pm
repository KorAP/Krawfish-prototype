package Krawfish::Koral::Corpus::Any;
use parent 'Krawfish::Koral::Corpus';
use Krawfish::Corpus::All;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless {
    any => 1
  }, $class;
};

sub is_any {
  1;
};

sub is_nothing {
  0;
};

sub type {
  'any';
};

sub is_leaf {
  1;
};

sub to_string {
  '[1]';
};

sub optimize {
  my ($self, $index) = @_;
  return $index->lives->pointer; # Krawfish::Corpus::All->new($index);
};


1;
