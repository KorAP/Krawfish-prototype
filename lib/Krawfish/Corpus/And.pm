package Krawfish::Corpus::And;
use parent 'Krawfish::Corpus';
use List::Util qw/min/;
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
    second => shift,
    doc_id => undef
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

  print_log('vc_and', 'Next and operation') if DEBUG;

  my $first = $self->{first}->current;
  my $second = $self->{second}->current;

  unless ($first || $second) {
     $self->{doc_id} = undef;
     return;
  };

  while ($first && $second) {

    print_log('vc_and', 'Both operands available') if DEBUG;

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
  return;
};


sub to_string {
  my $self = shift;
  return 'and(' . $self->{first}->to_string . ',' . $self->{second}->to_string . ')';
};


# The maximum frequency is the minimum of both query frequencies
sub max_freq {
  my $self = shift;
  min($self->{first}->max_freq, $self->{second}->max_freq);
};


1;
