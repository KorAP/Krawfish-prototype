package Krawfish::Koral::Meta::Node::Limit;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 1;

sub new {
  my $class = shift;

  my $self = bless {
    query => shift,
    start_index => shift,
    items_per_page => shift
  }, $class;
};


# Get identifiers
sub identify {
  my ($self, $dict) = @_;

  $self->{query} = $self->{query}->identify($dict);

  return if $self->{items_per_page} == 0;

  return $self;
};


sub to_string {
  my $self = shift;
  return 'limit(' . $self->{start_index} . '-' .
    ($self->{start_index} + $self->{items_per_page}) .
    ':' .
    $self->{query}->to_string .
    ')';
};


1;
