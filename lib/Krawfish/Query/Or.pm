package Krawfish::Query::Or;
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

# Current span object
sub current {
  my $self = shift;
  return unless defined $self->{doc_id};
  return Krawfish::Posting->new(
    doc_id => $self->{doc_id},
    start  => $self->{start},
    end    => $self->{end}
  );
};

sub next {
  my $self = shift;
  $self->init;

  my $first = $self->{first}->current;
  my $second = $self->{second}->current;

  my $curr = 'first';

  # First span is no longer available
  if (!$first) {

    return unless $second;
    print "  >> Current is second\n";
    $curr = 'second';
  }

  # Second span is no longer available
  elsif (!$second) {
    print "  >> Current is first\n";
    $curr = 'first';
  }

  elsif ($first->doc_id < $second->doc_id) {
    print "  >> Current is first\n";
    $curr = 'first';
  }
  elsif ($first->doc_id > $second->doc_id) {
    print "  >> Current is second\n";
    $curr = 'second';
  }
  elsif ($first->start < $second->start) {
    print "  >> Current is first\n";
    $curr = 'first';
  }
  elsif ($first->start > $second->start) {
    print "  >> Current is second\n";
    $curr = 'second';
  }
  elsif ($first->end < $second->end) {
    print "  >> Current is first\n";
    $curr = 'first';
  }
  elsif ($first->end > $second->end) {
    print "  >> Current is second\n";
    $curr = 'second';
  }
  else {
    print "  >> Current is first\n";
    $curr = 'first';
  };

  my $curr_post = $self->{$curr}->current;
  $self->{doc_id} = $curr_post->doc_id;
  $self->{start} = $curr_post->start;
  $self->{end} = $curr_post->end;
  print "  >> Current " . $self->current->to_string . "\n";
  $self->{$curr}->next;
  return 1;
};


sub to_string {
  my $self = shift;
  return 'or(' . $self->{first}->to_string . ',' . $self->{second}->to_string . ')';
};

1;
