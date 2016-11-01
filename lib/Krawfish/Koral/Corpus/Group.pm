package Krawfish::Koral::Corpus::Group;
use parent 'Krawfish::Koral::Corpus';
use strict;
use warnings;

sub new {
  my $class = shift;
  bless {
    type => shift,
    operands => [@_]
  }, $class;
};

sub plan {
  ...
};

sub to_koral_fragment {
  my $self = shift;
  return {
    '@type' => 'koral:fieldGroup',
    operation => 'operation:' . $self->{type},
    operands => [ map { $_->to_koral_fragment } @{$self->{operands}} ]
  };
};

1;
