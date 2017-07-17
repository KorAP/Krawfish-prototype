package Krawfish::Koral::Query::Constraint::ClassDistance;
use Krawfish::Query::Constraint::ClassDistance;
use strict;
use warnings;

# This will add a class to the distance between both queries

sub new {
  my $class = shift;
  my $nr = shift // 1;
  bless \$nr, $class;
};


sub to_string {
  my $self = shift;
  return 'class=' . $$self;
};


sub normalize {
  $_[0];
};


sub optimize {
  my $self = shift;
  Krawfish::Query::Constraint::ClassDistance->new($$self);
};


sub plan_for {
  warn 'DEPRECATED';
  my $self = shift;
  Krawfish::Query::Constraint::ClassDistance->new($$self);
};


1;
