package Krawfish::Result::Node::Sort;
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
    query => shift,
    sort => shift
  }, $class;
};


sub to_string {
  my $self = shift;
  return 'sort(' . join(',', map { $_->to_string } @{$self->{sort}}) . ':' . $self->{query}->to_string . ')';
};

sub next {
  $_[0]->{query}->next;
};


1;
