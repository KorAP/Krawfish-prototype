package Krawfish::Koral::Query::Sequence;
use parent 'Krawfish::Koral::Query';
use strict;
use warnings;

sub new {
  my $class = shift;
  bless [@_], $class;
};

sub append {
  push @$_, shift;
};

sub prepend {
  unshift @$_, shift;
};

sub to_koral_fragment {
  my $self = shift;
  return {
    '@type' => 'koral:group',
    'operation' => 'operation:sequence',
    'operands' => [
      map { $_->to_koral_fragment } @$self
    ]
  };
};

1;
