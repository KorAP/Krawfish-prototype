package Krawfish::Result::Aggregate::Base;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless \(my $self = ''), $class;
};

sub each_doc {};

sub each_match {};

sub on_finish {};

sub to_string {
  ...
};

1;
