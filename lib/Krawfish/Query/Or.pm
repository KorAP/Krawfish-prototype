package Krawfish::Query::Or;
use parent 'Krawfish::Query';
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 1;

sub new {
  my $class = shift;
  bless {
    first => shift,
    second => shift
  }, $class;
};

sub init  {
  return if $_[0]->{init}++;
  if (DEBUG) {
    print_log(
      'or',
      'Init ' . $_[0]->{first}->to_string . ' and ' . $_[0]->{second}->to_string
    );
  };
  $_[0]->{first}->next;
  $_[0]->{second}->next;
};


sub next {
  my $self = shift;
  $self->init;

  my $first = $self->{first}->current;
  my $second = $self->{second}->current;

  my $curr = 'first';

  if (DEBUG) {
    print_log(
      'or',
      'Which alternative is first in order: ' .
      ($first ? $first->to_string : '?') . ' or ' .
        ($second ? $second->to_string : '?')
    );
  };

  # First span is no longer available
  if (!$first) {

    unless ($second) {
      $self->{doc_id} = undef;
      return;
    };
    print_log('or', 'Current is second (a) - no first available') if DEBUG;
    $curr = 'second';
  }

  # Second span is no longer available
  elsif (!$second) {
    print_log('or', 'Current is first (b) - no second available') if DEBUG;
    $curr = 'first';
  }

  elsif ($first->doc_id < $second->doc_id) {
    print_log('or', 'Current is first (based on document id)') if DEBUG;
    $curr = 'first';
  }
  elsif ($first->doc_id > $second->doc_id) {
    print_log('or', 'Current is second (based on document id)') if DEBUG;
    $curr = 'second';
  }
  elsif ($first->start < $second->start) {
    print_log('or', 'Current is first (based on start position)') if DEBUG;
    $curr = 'first';
  }
  elsif ($first->start > $second->start) {
    print_log('or', 'Current is second (based on start position)') if DEBUG;
    $curr = 'second';
  }
  elsif ($first->end < $second->end) {
    print_log('or', 'Current is first (based on end position)') if DEBUG;
    $curr = 'first';
  }
  elsif ($first->end > $second->end) {
    print_log('or', 'Current is second (based on end position)') if DEBUG;
    $curr = 'second';
  }
  else {
    print_log('or', 'Current is first (just because both are identical)') if DEBUG;
    $curr = 'first';
  };

  my $curr_post    = $self->{$curr}->current;
  $self->{doc_id}  = $curr_post->doc_id;
  $self->{start}   = $curr_post->start;
  $self->{end}     = $curr_post->end;
  $self->{payload} = $curr_post->payload->clone;

  if (DEBUG) {
    print_log('or', 'So current is ' . $self->current->to_string);
    print_log('or', "Next on $curr");
  };
  $self->{$curr}->next;
  return 1;
};


sub to_string {
  my $self = shift;
  return 'or(' . $self->{first}->to_string . ',' . $self->{second}->to_string . ')';
};


sub max_freq {
  my $self = shift;

  if ($self->{first}->max_freq == -1 || $self->{second}->max_freq == -1) {
    return -1;
  }
  else {
    return $self->{first}->max_freq + $self->{second}->max_freq;
  };
};


sub filter_by {
  my ($self, $corpus) = @_;
  $self->{first} = $self->{first}->filter_by($corpus);
  $self->{second} = $self->{second}->filter_by($corpus);
  $self;
};


1;
