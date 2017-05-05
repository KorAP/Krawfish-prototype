package Krawfish::Corpus::Class;
use Krawfish::Util::Bits 'bitstring';
use Krawfish::Log;
use strict;
use warnings;

# "class" queries are useful with "or" queries.
# They return the information, if a match
# occurred in the subcorpus, similar to
# "class" queries for spans.

# Instead of payloads, each document match
# has one byte and can flag that byte at
# the classes position, meaning
# only 8 classes are supported.

# TODO:
#   Alternatively there could be a Compare()
#   query

use constant DEBUG => 0;

sub new {
  my ($class, $corpus, $number) = @_;

  # 2 bytes flag for 16 classes
  my $flag = 0b0000_0000_0000_0000 | (1 << ($number - 1));

  bless {
    corpus => $corpus,
    flag => $flag,
    number => $number
  }, $class;
};


# Return flag in bit stringification
sub flag {
  bitstring($_[0]->{flag});
};


# Iterate over corpus and add classes
sub next {
  my $self = shift;
  if ($self->{corpus}->next) {
    my $current = $self->{corpus};

    $self->{doc_id} = $current->doc_id;
    $self->{flags} = $current->flags | $self->{flag};

    print_log('class', 'Classed corpus matched: ' . $self->current->to_string) if DEBUG;

    return 1;
  };

  $self->{doc_id} = undef;
  return;
};

sub skip_to;

sub to_string {
  my $self = shift;
  my $str = 'corpusClass(';
  $str .= $self->{number} . ':';
  $str .= $self->{corpus}->to_string . ')';
  return $str;
};

1;
