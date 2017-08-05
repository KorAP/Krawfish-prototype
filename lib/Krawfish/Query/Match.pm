package Krawfish::Query::Match;
use parent 'Krawfish::Query';
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 1;

sub new {
  my $class = shift;
  bless {
    doc => shift,
    start => shift,
    end => shift
  }, $class;
};


sub init {
  return if $_[0]->{init}++;
  if (DEBUG) {
    print_log('match', 'Init ' . $_[0]->{doc}->to_string);
  };
  $_[0]->{doc}->next;
};


# Forward to next match
sub next {
  my $self = shift;

  $self->init;

  print_log('match', 'Check next valid match') if DEBUG;

  my $doc = $self->{doc}->current;

  if (!$doc) {
    $self->{doc_id} = undef;
    print_log('match', 'No more document') if DEBUG;
    return;
  };

  print_log('match', 'Document ' . $doc->doc_id . ' is valid') if DEBUG;

  $self->{doc_id} = $doc->doc_id;
  $self->{start} = $self->start;
  $self->{end} = $self->end;

  # $self->{payload} = $current->payload->add(
  #   0,
  #   $self->{number},
  #   $self->{start},
  #   $self->{end}
  # );

  $self->{doc}->next;

  print_log('match', 'Defined match ' . $self->current->to_string) if DEBUG;
  return 1;
};


# Match can only occur once (although this requires a filter!)
sub max_freq {
  1;
};


sub to_string {
  my $self = shift;
  return '[[' . $self->{doc}->to_string . ':' . $self->start . '-' . $self->end . ']]';
};


sub start {
  $_[0]->{start};
};


sub end {
  $_[0]->{end};
};


# This is useful to, e.g., make sure the document is live
sub filter_by {
  my ($self, $corpus) = @_;

  # TODO: Check always that the query isn't moved forward yet!
  $self->{doc} = Krawfish::Corpus::And->new($self->{doc}, $corpus);
  $self;
};

1;
