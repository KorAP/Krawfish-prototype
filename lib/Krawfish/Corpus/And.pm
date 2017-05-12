package Krawfish::Corpus::And;
use parent 'Krawfish::Corpus';
use Krawfish::Log;
use strict;
use warnings;

# TODO:
#   Create a version of AndWithFlags

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

  return unless $first || $second;

  while ($first && $second) {
    if ($first->doc_id == $second->doc_id) {
      $self->{doc_id} = $first->doc_id;
      $self->{first}->next;
      $self->{second}->next;
      return 1;
    }

    elsif ($first->doc_id < $second->doc_id) {
      unless (defined $self->{first}->skip_doc($second->doc_id)) {
        $self->{doc_id} = undef;
        return;
      }
      else {
        $first = $self->{first}->current;
      };
    }

    else {
      unless (defined $self->{second}->skip_doc($first->doc_id)) {
        $self->{doc_id} = undef;
        return;
      }
      else {
        $second = $self->{second}->current;
      };
    };
  };

  $self->{doc_id} = undef;
  return 0;
};


sub to_string {
  my $self = shift;
  return 'and(' . $self->{first}->to_string . ',' . $self->{second}->to_string . ')';
};

1;
