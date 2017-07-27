package Krawfish::Node::Sort;
use strict;
use warnings;


# This will simply mergesort the inmcoming
# streams using next and prepare 'criterion'
# for current.

# May need to return Krawfish::Posting::Sorted with a 'criterion' array.

# Instead of next() followed by current(), this should use
# next_current() and - for matches - next_match()

sub new {
  my $class = shift;
  return bless {
  }, $class;
};

sub to_string {
  ...
};

1;
