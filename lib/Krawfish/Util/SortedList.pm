package Krawfish::Util::SortedList;
use parent 'Krawfish::Query';
use strict;
use warnings;
use Krawfish::Posting::Sorted;


use constant {
  DEBUG   => 0,
  SAME    => 1,
  VALUE   => 2,
  MATCHES => 3
};


sub new {
  my $class = shift;
  bless {
    list => shift,
    pos => -1
  }, $class;
};

sub length {
  scalar @{$_[0]->{list}};
};

sub next {
  $_[0]->{pos}++ < $_[0]->length;
};

sub current {
  my $self = shift;
  return $self->{list}->[$self->{pos}];
};


1;
