package Krawfish::Result::Segment::Aggregate::Base;
use strict;
use warnings;

# Does not need anything in the object
sub new {
  my $class = shift;
  bless \(my $self = ''), $class;
};

# Per default do nothing
sub each_doc {};

# Per default do nothing
sub each_match {};

# Per default do nothing
sub on_finish {};

# Not implemented on base
sub to_string {
  ...
};

1;
