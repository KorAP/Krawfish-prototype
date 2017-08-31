package Krawfish::Index::Postings::Lift;
use Krawfish::Index::Postings::Empty;
# use Krawfish::Index::Postings::Buffer;
use strict;
use warnings;

use constant {
  DEBUG   => 0,
  TERM_ID => 0,
  START   => 1,
  LENGTH  => 2,
  FREQ    => 3,
  BUFFER  => 4
};


# Construct a new lifter
sub new {
  my $class = shift;
  bless {
    buffer_size => shift,
    file => shift,
    lists => []
  }, $class;
};


# Add a postings list to lift
sub add {
  my ($self, $info) = @_;

  # $term_id, $start, $length, $freq
  # buffer is initially undefined
  push @{$self->{lists}}, [@$info, undef];
};


# Get the postingslist based on the term id
# This will initialize the buffers to lift
sub get {
  my ($self, $term_id) = @_;

  # TODO:
  #   For a lot of term ids, it may be beneficial to use
  #   a different search strategy

  my $list = $self->{lists};
  foreach my $entry (@$list) {
    if ($entry->[TERM_ID] == $term_id) {

      return $entry->[BUFFER] if $entry->[BUFFER];

      # Initialize the buffer for the postings list
      $entry->[BUFFER] = Krawfish::Index::Postings::Buffer->new(
        $term_id,
        $entry->[START],
        $entry->[LENGTH],
        $entry->[FREQ],
        $self->{buffer_size}
      );

      return $entry->[BUFFER];
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
