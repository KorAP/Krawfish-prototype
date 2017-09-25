package Krawfish::Koral::Meta::Aggregate::Frequencies;
use Krawfish::Meta::Segment::Aggregate::Frequencies;
use strict;
use warnings;

sub new {
  my $class = shift;
  my $self = '';
  bless \$self, $class;
};


sub type {
  'freq'
};


sub normalize {
  $_[0];
};



sub identify {
  $_[0];
};


sub to_string {
  'freq';
};


# Materialize query for segment search
sub optimize {
  my ($self, $segment) = @_;

  return Krawfish::Meta::Segment::Aggregate::Frequencies->new;
};


1;
