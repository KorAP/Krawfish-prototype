package Krawfish::Corpus::Without;
use parent 'Krawfish::Corpus';
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

  # No first operand
  return unless $first;

  while ($first && $second) {
    if ($first->doc_id == $second->doc_id) {
      $self->{first}->next;
      $self->{second}->next;
    }

    elsif ($first->doc_id < $second->doc_id) {
      $self->{doc_id} = $first->doc_id;
      $self->{first}->next;
      return 1;
    }

    else {
      $self->{second}->next;
    };

    $first = $self->{first}->current;
    $second = $self->{second}->current;
  };

  $self->{doc_id} = undef;
  return 0;
};

sub freq {
  $_[0]->{first}->freq;
};


sub to_string {
  my $self = shift;
  return 'andNot(' . $self->{first}->to_string . ',' . $self->{second}->to_string . ')';
};

1;
