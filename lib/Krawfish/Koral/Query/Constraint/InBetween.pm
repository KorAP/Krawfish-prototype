package Krawfish::Koral::Query::Constraint::InBetween;
use Krawfish::Query::Constraint::InBetween;
use strict;
use warnings;

# TODO:
#   Support foundry for tokenization
#   and gaps parameter.


sub new {
  my $class = shift;
  bless {
    min => shift,
    max => shift
  }, $class;
};

sub to_string {
  my $self = shift;
  return 'between=' . $self->{min} . '-' . $self->{max};
};


# Probably introduce opt for min==0 constraint
sub normalize {
  $_[0];
};

sub optimize {
  my ($self, $index) = @_;

  return Krawfish::Query::Constraint::InBetween->new($self->{min}, $self->{max});
};

1;
