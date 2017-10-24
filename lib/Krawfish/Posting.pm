package Krawfish::Posting;
use overload '""' => sub { $_[0]->to_string }, fallback => 1;
use Krawfish::Util::Bits;
use Krawfish::Posting::Payload;
use Krawfish::Log;
use bytes;
use strict;
use warnings;

use constant DEBUG => 0;

# Constructor
sub new {
  my $class = shift;
  bless { @_ }, $class;
};


# Current document
sub doc_id {
  return $_[0]->{doc_id};
};


# Corpus classes
sub flags {
  my ($self, $flags) = @_;


  # Class 0 is set per default
  $self->{flags} //= 0b1000_0000_0000_0000;

  return $self->{flags} unless defined $flags;
  return $self->{flags} & $flags;
};


# Returns a list of matching query corpus classes
sub corpus_classes {
  my ($self, $query_flags) = @_;

  # Returns all flags requested and all flags existing
  my $intersect = $self->flags($query_flags);

  my @list = ();

  if (DEBUG) {
    print_log(
      'post',
      'Intersection between stored and queried classes is <'.
        reverse(bitstring($intersect)) . '>'
      );
  };

  # Remove zero class
  $intersect &= 0b0111_1111_1111_1111;

  # Initialize move variable
  my $move = 0b0100_0000_0000_0000;

  my $i = 1;

  # As long as there a set bits ...
  while ($intersect) {

    if (DEBUG) {
      print_log(
        'post',
        'Check move ' . reverse(bitstring($move)) . ' and intersect ' .
          reverse(bitstring($intersect))
      );
    };

    if ($intersect & $move) {
      if (DEBUG) {
        print_log(
          'post',
          'Move ' . reverse(bitstring($move)) . ' matches ' . reverse(bitstring($intersect))
        );
      };
      push @list, $i;
      $intersect &= ~$move;
    };
    $move >>= 1;
    $i++;
  };

  # Return list of valid classes
  return @list;
};


# Check if two postings are identical
# WARNING:
#   This should compare payloads separately,
#   because classes may be in different order,
#   though resulting in identical postings
# TODO:
#   Serialization is also bad for flags!!!
sub same_as {
  my ($self, $comp) = @_;
  return unless $comp;
  return $self->to_string eq $comp->to_string;
};


# Stringification
sub to_string {
  my $self = shift;
  my $str = '[' . $self->{doc_id};

  # In case a class != 0 is set - serialize
  if ($self->flags & 0b0111_1111_1111_1111) {
    $str .= '!' . join(',', $self->corpus_classes);
  };

  $str . ']';
};



1;
