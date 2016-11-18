package Krawfish::Query::Constraint::ClassDistance;
use strict;
use warnings;

# This is no real check,
# it simply marks the distance between two spans using a class payload

sub new {
  my $class = shift;
  my $nr = shift;
  bless \$nr, $class;
};

sub check {
  my $self = shift;
  my ($payload, $first, $second) = @_;

  # [a]..[b]
  if ($first->end < $second->start) {
    $payload->add(
      0,
      $$self,
      $first->end,
      $second->start - 1
    );
  }

  # [b]..[a]
  elsif ($second->end < $first->start) {
    $payload->add(
      0,
      $$self,
      $second->end,
      $first->start - 1
    );
  };

  return 0b0111;
};

sub to_string {
  'class=' . (0 + ${$_[0]});
};


1;
