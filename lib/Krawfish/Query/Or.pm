package Krawfish::Query::Or;
use parent 'Krawfish::Query';
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

sub new {
  my $class = shift;
  bless {
    first => shift,
    second => shift
  }, $class;
};

sub init  {
  return if $_[0]->{init}++;
  $_[0]->{first}->next;
  $_[0]->{second}->next;
};


sub next {
  my $self = shift;
  $self->init;

  my $first = $self->{first}->current;
  my $second = $self->{second}->current;

  my $curr = 'first';

  # First span is no longer available
  if (!$first) {

    unless ($second) {
      $self->{doc_id} = undef;
      return;
    };
    print_log('or', 'Current is second (a)') if DEBUG;
    $curr = 'second';
  }

  # Second span is no longer available
  elsif (!$second) {
    print_log('or', 'Current is first (b)') if DEBUG;
    $curr = 'first';
  }

  elsif ($first->doc_id < $second->doc_id) {
    print_log('or', 'Current is first (1)') if DEBUG;
    $curr = 'first';
  }
  elsif ($first->doc_id > $second->doc_id) {
    print_log('or', 'Current is second (1)') if DEBUG;
    $curr = 'second';
  }
  elsif ($first->start < $second->start) {
    print_log('or', 'Current is first (2)') if DEBUG;
    $curr = 'first';
  }
  elsif ($first->start > $second->start) {
    print_log('or', 'Current is second (2)') if DEBUG;
    $curr = 'second';
  }
  elsif ($first->end < $second->end) {
    print_log('or', 'Current is first (3)') if DEBUG;
    $curr = 'first';
  }
  elsif ($first->end > $second->end) {
    print_log('or', 'Current is second (3)') if DEBUG;
    $curr = 'second';
  }
  else {
    print_log('or', 'Current is first (4)') if DEBUG;
    $curr = 'first';
  };

  my $curr_post = $self->{$curr}->current;
  $self->{doc_id} = $curr_post->doc_id;
  $self->{start} = $curr_post->start;
  $self->{end} = $curr_post->end;
  if (DEBUG) {
    print_log('or', 'Current ' . $self->current->to_string);
    print_log('or', "Next on $curr");
  };
  $self->{$curr}->next;
  return 1;
};


sub to_string {
  my $self = shift;
  return 'or(' . $self->{first}->to_string . ',' . $self->{second}->to_string . ')';
};

1;
