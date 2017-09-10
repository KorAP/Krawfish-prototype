package Krawfish::Koral::Meta::Aggregate::Length;
use Krawfish::Result::Segment::Aggregate::Length;
use strict;
use warnings;

sub new {
  my $class = shift;
  my $self = '';
  bless \$self, $class;
};

sub type {
  'length'
};


sub normalize {
  $_[0];
};


sub identify {
  $_[0];
};


sub to_string {
  'length';
};


# Materialize query for segment search
sub optimize {
  my ($self, $segment) = @_;

  return Krawfish::Result::Segment::Aggregate::Length->new;
};


1;
