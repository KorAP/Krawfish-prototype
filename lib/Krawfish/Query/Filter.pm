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


sub clone {
  my $self = shift;
  __PACKAGE__->new(
    $self->{span}->clone,
    $self->{docs}->clone
  );
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

  my $span = $self->{span}->current;

  # Invalidate current if no current span exists
  unless ($span) {
    $self->{doc_id} = undef;
    return;
  };

  my $doc = $self->{docs}->current;

  # Invalidate current if no current doc exists
  unless ($doc) {
    $self->{doc_id} = undef;
    return;
  };

  # TODO:
  #   Replace with same_doc
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


# Get the maximum frequency of the term
sub max_freq {
  my $self = shift;
  # my $freq = 0;

  # $self->init;

  # print_log('filter', 'Count valid spans') if DEBUG;

  # Iterate over all docs and collect frequencies
  #while ($self->{span}->same_doc($self->{docs})) {
  #  $freq += $self->{span}->freq_in_doc;
  #  $self->{span}->next_doc or last;
  #};

  return $self->{span}->max_freq;
};


sub filter_by {
  my ($self, $corpus) = @_;

  # TODO: Check always that the query isn't moved forward yet!
  $self->{docs} = Krawfish::Corpus::And->new($self->{docs}, $corpus->clone);
  $self;
};


1;
