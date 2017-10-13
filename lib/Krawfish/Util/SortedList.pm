package Krawfish::Util::SortedList;
use parent 'Krawfish::Query';
use Krawfish::Posting::List;
use strict;
use warnings;


use constant {
  DEBUG   => 0,
  SAME    => 1,
  VALUE   => 2,
  MATCHES => 3
};


# Constructor
sub new {
  my $class = shift;
  bless {
    list => shift,
    pos => -1
  }, $class;
};


# Get list lenght
sub length {
  scalar @{$_[0]->{list}};
};


# Move to next item in list
sub next {
  $_[0]->{pos}++ < $_[0]->length;
};


# Get current item
sub current {
  my $self = shift;
  return $self->{list}->[$self->{pos}];
};


1;
