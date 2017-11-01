package Krawfish::Posting;
use Role::Tiny;
requires qw/doc_id
           flags
           corpus_classes
           same_as
           to_string
           clone/;
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
  return flags_to_classes($intersect & 0b0111_1111_1111_1111);
};


# Check if two postings are identical
sub same_as {
  my ($self, $comp) = @_;
  return unless $comp;
  return if $self->doc_id != $comp->doc_id;
  return if $self->flags != $comp->flags;
  return 1;
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
