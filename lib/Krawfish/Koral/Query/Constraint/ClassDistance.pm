package Krawfish::Koral::Query::Constraint::ClassDistance;
use Krawfish::Query::Constraint::ClassDistance;
use strict;
use warnings;

sub new {
  my $class = shift;
  my $nr = shift;
  bless \$nr, $class;
};

sub to_string {
  my $self = shift;
  return 'class=' . $$self;
};

sub plan_for {
  my $self = shift;
  Krawfish::Query::Constraint::ClassDistance->new($$self);
};

1;
