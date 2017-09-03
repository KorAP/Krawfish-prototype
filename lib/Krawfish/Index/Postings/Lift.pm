package Krawfish::Index::Postings::Lift;
use Krawfish::Index::Postings::Empty;
# TODO:
#   Use store postings lists with PTI
use Krawfish::Index::PostingsList;
use strict;
use warnings;

# Lift the postingslist file using
#
# - mmap
#
#   or
#
# - (possibly better suited for our use case)
#   Load the postings lists completely and store them
#   in the coordinator for multiple requests. Use a
#   mtf list structure to make the list remember the latest
#   structures. Once a given ratio is exceeded, or the size
#   of newly to fetch structures exceed the ratio, forget the latest
#   remembered structures.
#   Always add newly requested structures to the top of the list.
#   The reference to the cached postings list is added
#   to the coordination list.

use constant {
  DEBUG   => 0,
  TERM_ID => 0,
  START   => 1,
  LENGTH  => 2,
  FREQ    => 3,
  PTI     => 4,
  LIST    => 5
};

# See
#   https://stackoverflow.com/questions/9817233/why-mmap-is-faster-than-sequential-io
#   http://lkml.iu.edu/hypermail/linux/kernel/0802.0/1496.html
#   http://lkml.iu.edu/hypermail/linux/kernel/0802.0/1496.html
#   https://marc.info/?l=linux-kernel&m=95496636207616&w=2


# Construct a new lifter
sub new {
  my $class = shift;

  my $self = bless {
    file => shift,
    lists => []
  }, $class;

  # Mmap offsets - could be used
  my $start = shift;
  my $length = shift;

  $self->{mmap} = _mmap($self->{file});
  return $self;
};


# Add a postings list to lift
sub add {
  my ($self, $info) = @_;

  # $term_id, $start, $length, $freq, $pti
  # LIST is initially undefined
  push @{$self->{lists}}, [@$info, undef];
};


# Get the postingslist based on the term id
sub get {
  my ($self, $term_id) = @_;

  # TODO:
  #   For a lot of term ids, it may be beneficial to use
  #   a different search strategy

  my $list = $self->{lists};
  foreach my $entry (@$list) {
    if ($entry->[TERM_ID] == $term_id) {

      return $entry->[LIST] if $entry->[LIST];

      # Initialize the postings list based on the PTI!
      # TODO:
      #   Use a store version
      # TODO:
      #   If the offsets for mmap are set, these need to be resprected
      $entry->[LIST] = Krawfish::Index::PostingsList->new(
        $term_id,
        $entry->[START],
        $entry->[LENGTH],
        $entry->[FREQ]
      );

      return $entry->[LIST];
    }

    # There is no entry for this term id
    elsif ($entry->[TERM_ID] > $term_id) {

      # Return an empty postings list
      return Krawfish::Index::Postings::Empty->new($term_id);
    };

    # Check next position
  };
};

1;
