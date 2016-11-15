package Krawfish::Query::Or;
use parent 'Krawfish::Query';
use strict;
use warnings;

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
    print "  >> Current is second (a)\n";
    $curr = 'second';
  }

  # Second span is no longer available
  elsif (!$second) {
    print "  >> Current is first (b)\n";
    $curr = 'first';
  }

  elsif ($first->doc_id < $second->doc_id) {
    print "  >> Current is first (1)\n";
    $curr = 'first';
  }
  elsif ($first->doc_id > $second->doc_id) {
    print "  >> Current is second (1)\n";
    $curr = 'second';
  }
  elsif ($first->start < $second->start) {
    print "  >> Current is first (2)\n";
    $curr = 'first';
  }
  elsif ($first->start > $second->start) {
    print "  >> Current is second (2)\n";
    $curr = 'second';
  }
  elsif ($first->end < $second->end) {
    print "  >> Current is first (3)\n";
    $curr = 'first';
  }
  elsif ($first->end > $second->end) {
    print "  >> Current is second (3)\n";
    $curr = 'second';
  }
  else {
    print "  >> Current is first (4)\n";
    $curr = 'first';
  };

  my $curr_post = $self->{$curr}->current;
  $self->{doc_id} = $curr_post->doc_id;
  $self->{start} = $curr_post->start;
  $self->{end} = $curr_post->end;
  print "  >> Current " . $self->current->to_string . "\n";
  print "  >> Next on $curr\n";
  $self->{$curr}->next;
  return 1;
};


sub to_string {
  my $self = shift;
  return 'or(' . $self->{first}->to_string . ',' . $self->{second}->to_string . ')';
};

1;
