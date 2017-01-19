package Krawfish::Query::Filter;
use parent 'Krawfish::Query';
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

# Filters a term to check, if it is
# in a supported document

sub new {
  my $class = shift;
  bless {
    span => shift,
    docs => shift
  }, $class;
};


# Initialize spans
sub init {
  return if $_[0]->{init}++;
  print_log('filter', 'Init filter spans') if DEBUG;
  $_[0]->{span}->next;
  $_[0]->{docs}->next;
};


# Next filtered item
sub next {
  my $self = shift;

  $self->init;

  print_log('filter', 'Check next valid span') if DEBUG;

  my $span = $self->{span}->current or return;
  my $doc = $self->{docs}->current or return;

  # to_same_doc
  while ($span->doc_id != $doc->doc_id) {
    print_log('filter', 'Current span is not in docs') if DEBUG;

    if ($span->doc_id < $doc->doc_id) {
      print_log('filter', 'Forward span') if DEBUG;
      $self->{span}->next or return;
      $span = $self->{span}->current;
    }
    else {
      print_log('filter', 'Forward docs') if DEBUG;
      $self->{docs}->next or return;
      $doc = $self->{docs}->current;
    };
  };

  print_log('filter', 'Current span is in docs') if DEBUG;

  $self->{doc_id} = $span->doc_id;
  $self->{start}  = $span->start;
  $self->{end}    = $span->end;
  $self->{payload} = $span->payload;

  # Forward span
  $self->{span}->next;

  return 1;
};

sub to_string {
  my $self = shift;
  my $str = 'filter(';
  $str .= $self->{span}->to_string . ',';
  $str .= $self->{docs}->to_string;
  return $str . ')';
};

1;
