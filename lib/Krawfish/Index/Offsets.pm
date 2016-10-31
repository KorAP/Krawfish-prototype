package Krawfish::Index::Offsets;
use strict;
use warnings;

# TODO: Probably rename to "Segments"
# Store offsets for direct access using doc id and pos

# Constructor
sub new {
  my $class = shift;
  bless {
    file => shift
  }, $class;
};

# TODO: Better store length ...
# Store offsets
sub store {
  my $self = shift;

  # Get data to store per segment
  my ($doc_id, $segment, $start_char, $end_char) = @_;

  # Store all segments
  $self->{$doc_id . '#' . $segment} = [$start_char, $end_char];
  return $self;
};


# Get offsets
sub get {
  my $self = shift;
  my ($doc_id, $segment) = @_;
  return $self->{$doc_id . '#' . $segment};
};

1;
