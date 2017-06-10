package Krawfish::Koral::Corpus::Negation;
use parent 'Krawfish::Koral::Corpus';
use strict;
use warnings;
use constant DEBUG => 0;

warn 'DEPRECATED';


sub new {
  my $class = shift;
  bless {
    operand => shift
  }, $class;
};

sub type {
  'neg';
};

sub operand {
  $_[0]->{operand};
};

sub is_negative {
  1;
};

sub has_classes {
  $_[0]->{operand}->has_classes;
};

sub to_koral_fragment {
  my $self = shift;
};


1;
