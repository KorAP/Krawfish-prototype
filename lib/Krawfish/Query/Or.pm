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
  return Krawfish::Posting->new(
    doc_id => $self->{doc_id},
    start  => $self->{start},
    end    => $self->{end},
  );
};

sub next {
  my $self = shift;
  $self->init;

  my $first = $self->{first}->current;
  my $second = $self->{second}->current;

  my $curr = $first;

  # First span is no longer available
  if (!$first) {

    return unless $second;
    $curr = $second;
  }

  # Second span is no longer available
  elsif (!$second) {
    $curr = $first
  }

  elsif ($first->doc_id < $second->doc_id) {
    $curr = $first;
  }
  elsif ($first->doc_id > $second->doc_id) {
    $curr = $second;
  }
  elsif ($first->start < $second->start) {
    $curr = $first;
  }
  elsif ($first->start > $second->start) {
    $curr = $second;
  }
  elsif ($first->end < $second->end) {
    $curr = $first;
  }
  elsif ($first->end > $second->end) {
    $curr = $second;
  }
  else {
    $curr = $first;
  };

  $self->{doc_id} = $curr->doc_id;
  $self->{start} = $curr->start;
  $self->{end} = $curr->end;
  $curr->next;
  return 1;
}


sub to_string {
  my $self = shift;
  return '(' . $self->{first}->to_string . '|' . $self->{second}->to_string . ')';
};

1;
