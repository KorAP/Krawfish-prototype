package Krawfish::Query::Unique;
use strict;
use warnings;
use Role::Tiny::With;
use Krawfish::Log;

with 'Krawfish::Query';

# Filter duplicate postings

use constant DEBUG => 0;

# Constructor
sub new {
  my $class = shift;
  bless {
    span => shift,
    last => undef
  };
};


# Clone query
sub clone {
  my $self = shift;
  __PACKAGE__->new(
    $self->{span}->clone
  );
};


# Move to next posting
sub next {
  my $self = shift;

  print_log('unique', 'Next unique span') if DEBUG;

  my $span = $self->{span};
  while ($span->next) {
    my $current = $span->current;

    print_log('unique', 'Found ' . $current->to_string) if DEBUG;

    unless ($current->same_as($self->{last})) {

      print_log('unique', 'Span is unique') if DEBUG;

      $self->{last}    = $current;
      $self->{doc_id}  = $current->doc_id;
      $self->{flags}   = $current->flags;
      $self->{start}   = $current->start;
      $self->{end}     = $current->end;
      $self->{payload} = $current->payload;
      return 1;
    }
    elsif (DEBUG) {
      print_log('unique', 'Span is not unique');
    };
  };
  return;
};


# Stringification
sub to_string {
  return 'unique(' . $_[0]->{span}->to_string . ')';
};


# Get maximum frequency
sub max_freq {
  $_[0]->{span}->max_freq;
};


# Filter query by VC
sub filter_by {
  my ($self, $corpus) = @_;
  $self->{span} = $self->{span}->filter_by($corpus);
  return $self;
};


# Requires filtering
sub requires_filter {
  return $_[0]->{span}->requires_filter;
};


1;
