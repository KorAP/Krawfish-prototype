package Krawfish::Query::Unique;
use parent 'Krawfish::Query';
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

sub new {
  my $class = shift;
  bless {
    span => shift,
    last => undef
  };
};

sub next {
  my $self = shift;

  print_log('unique', 'Next unique span') if DEBUG;

  my $span = $self->{span};
  while ($span->next) {
    my $current = $span->current;

    print_log('unique', 'Found ' . $current->to_string) if DEBUG;

    unless ($current->is_identical($self->{last})) {

      print_log('unique', 'Span is unique') if DEBUG;

      $self->{last} = $current;
      $self->{doc_id} = $current->doc_id;
      $self->{start}  = $current->start;
      $self->{end}    = $current->end;
      $self->{payload} = $current->payload;
      return 1;
    }
    elsif (DEBUG) {
      print_log('unique', 'Span is not unique');
    };

    next;
  };
  return;
};

sub to_string {
  return 'unique(' . $_[0]->{span}->to_string . ')';
};

1;
