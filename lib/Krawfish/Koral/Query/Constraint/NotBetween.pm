package Krawfish::Koral::Query::Constraint::NotBetween;
use Krawfish::Query::Constraint::NotBetween;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless {
    query => shift
  }, $class;
};

sub to_string {
  my $self = shift;
  return 'notBetween=' . $self->{query}->to_string;
};

sub plan_for {
  my ($self, $index) = @_;
  my $query = $self->{query}->plan_for($index);
  Krawfish::Query::Constraint::NotBetween->new($query);
};

1;
