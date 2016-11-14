package Krawfish::Posting::Payload::Class;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless [@_], $class;
};

sub type { 'class' };

sub number {
  $_[0]->[0];
};

sub start {
  $_[0]->[1];
};

sub end {
  $_[0]->[2];
};


1;
