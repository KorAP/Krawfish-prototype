package Krawfish::Collection::Limit;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;


# Construct limitation collector
sub new {
  my $class = shift;
  bless {
    query => shift,
    start_index => shift,
    items_per_page => shift,
    pos => 0
  }, $class;
};


# Next if in limited area
sub next {
  my $self = shift;
  my $query = $self->{query};

  # Move to start index
  while ($self->{pos} < $self->{start_index}) {
    $self->{pos}++;
    $query->next or return;
    print_log('limit', 'Ignore match at position ' . $self->{pos}) if DEBUG;
  };

  # Position is under limit
  if ($self->{pos} < ($self->{start_index} + $self->{items_per_page})) {
    $self->{pos}++;
    print_log('limit', 'Collect match at position ' . $self->{pos}) if DEBUG;
    return $query->next;
  };
  return;
};


# Get current element
sub current {
  $_[0]->{query}->current;
};

# May return a hash reference with information
sub current_match;

# Stringify collector
sub to_string {
  my $self = shift;
  my $end = $self->{start_index} + $self->{items_per_page};
  my $str = 'collectLimit(';
  $str .= '[' . $self->{start_index} . '-' . $end . ']:';
  $str .= $self->{query}->to_string;
  return $str . ')';
};

1;
