package Krawfish::Query::Match;
use strict;
use warnings;
use Role::Tiny::With;
use Krawfish::Log;
use Krawfish::Util::Bits;

with 'Krawfish::Query';

# Get posting by doc id plus position and length.

# TODO:
#   Support classes and corpus classes

# TODO:
#   Support query classes

use constant DEBUG => 0;


# Constructor
sub new {
  my $class = shift;
  bless {
    doc => shift,
    start => shift,
    end => shift,
    payload => shift,
    flags => shift
  }, $class;
};


# Clone query
sub clone {
  my $self = shift;
  __PACKAGE__->new(
    $self->{doc}->clone,
    $self->{start},
    $self->{end},
    $self->{payload},
    $self->{flags}
  );
};


# Initialize
sub _init {
  return if $_[0]->{init}++;
  if (DEBUG) {
    print_log('match', 'Init ' . $_[0]->{doc}->to_string);
  };
  $_[0]->{doc}->next;
};


# Move to next posting
sub next {
  my $self = shift;

  $self->_init;

  print_log('match', 'Check next valid match') if DEBUG;

  my $doc = $self->{doc}->current;

  if (!$doc) {
    $self->{doc_id} = undef;
    print_log('match', 'No more document') if DEBUG;
    return;
  };

  print_log('match', 'Document ' . $doc->doc_id . ' is valid') if DEBUG;

  $self->{doc_id} = $doc->doc_id;

  # TODO:
  #   probably check if start and end is in a valid area
  # $self->{start} = $self->start;
  # $self->{end} = $self->end;

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


# Get maximum frequency
sub max_freq {
  # Match can only occur once
  # (although this requires a filter!)
  1;
};


# Stringification
sub to_string {
  my $self = shift;
  my $str = '[[' . $self->{doc}->to_string . ':' . $self->{start} . '-' . $self->{end};

  # In case a class != 0 is set - serialize
  if ($self->{flags} && $self->{flags} & 0b0111_1111_1111_1111) {
    $str .= '!' . join(',', flags_to_classes($self->{flags}));
  };

  $str .= '$' . $self->{payload}->to_string if $self->{payload};

  $str .= ']]';
};


# Get start position
#sub start {
#  $_[0]->{start};
#};


# Get end position
#sub end {
#  $_[0]->{end};
#};



# Filter query by VC
# This is useful to, e.g.,
# make sure the document is live
sub filter_by {
  my ($self, $corpus) = @_;

  # TODO:
  #   Check always that the query isn't moved forward yet!
  $self->{doc} = Krawfish::Corpus::And->new(
    $self->{doc},
    $corpus->clone
  );
  $self;
};


# Requires filter
sub requires_filter {
  0;
};


1;
