package Krawfish::Corpus::Class;
use strict;
use warnings;
use Role::Tiny;
use Krawfish::Util::Bits qw/classes_to_flags bitstring/;
use Krawfish::Log;

with 'Krawfish::Corpus';

# "class" queries are useful with "or" queries.
# They return the information, if a match
# occurred in the subcorpus, similar to
# "class" queries for spans.

# Instead of payloads, each document match
# has one byte and can flag that byte at
# the classes position, meaning
# only 8 classes are supported.

# Class queries may also be useful to
# have insights into the distribution
# of a virtual corpus, e.g.
#  {1:lang=de}|{2:lang!=de}
# getting the stats.

# It's also necessary to find out, how many documents
# may be filtered out by a certain query rewrite,
# e.g. freq(0,1: {1:author=Goethe} & license=free)
# will count all documents that are by Goethe and
# separately counts the filtered documents.

# TODO:
#   Alternatively there could be a Compare() query

use constant DEBUG => 0;

# Constructor
sub new {
  my ($class, $corpus, $number) = @_;

  # Check boundaries for class numbers
  return if $number < 1 || $number > 16;

  # 2 bytes flag for 16 classes
  my $flag = classes_to_flags($number);

  if (DEBUG) {
    print_log(
        'c_class',
        'Intitalized class ' . $number . ' with flag ' . reverse(bitstring($flag))
      );
    };


  bless {
    corpus => $corpus,
    flag   => $flag,
    number => $number
  }, $class;
};


# Clone query
sub clone {
  my $self = shift;
  __PACKAGE__->new(
    $self->{corpus}->clone,
    $self->{number}
  )
};


# Return flag in bit stringification
sub class_string {
  reverse(bitstring($_[0]->{flag}));
};


# Iterate over corpus and add classes
sub next {
  my $self = shift;

  # Move to next match
  if ($self->{corpus}->next) {

    # Get current posting
    my $current = $self->{corpus}->current;

    # Set current doc id
    $self->{doc_id} = $current->doc_id;

    # Set current flags
    $self->{flags} = $current->flags | $self->{flag};

    if (DEBUG) {
      print_log(
        'c_class',
        'Classed {' . $self->{number} . '} ' .
          'corpus matched: ' . $self->current->to_string
        );
    };

    return 1;
  };

  $self->{doc_id} = undef;
  return;
};


# Skip to target document
sub skip_doc {
  my $self = shift;
  if ($self->{corpus}->skip_doc(shift)) {
    my $current = $self->{corpus}->current;
    $self->{doc_id} = $current->doc_id;
    $self->{flags}  = $current->flags | $self->{flag};
    return $self->{doc_id};
  };
  $self->{doc_id} = undef;
  return;
};


# Stringification
sub to_string {
  my $self = shift;
  my $str = 'class(';
  $str .= $self->{number} . ':';
  $str .= $self->{corpus}->to_string . ')';
  return $str;
};


# Get maximum frequency
sub max_freq {
  $_[0]->{corpus}->max_freq;
};

1;
