package Krawfish::Index::Postings::Lift;
use Krawfish::Index::Postings::Empty;
# TODO:
#   Use store postings lists
use Krawfish::Index::PostingsList;
use strict;
use warnings;

use constant {
  DEBUG   => 0,
  TERM_ID => 0,
  START   => 1,
  LENGTH  => 2,
  FREQ    => 3,
  LIST  => 4
};


# Construct a new lifter
sub new {
  my $class = shift;

  my $self = bless {
    file => shift,
    lists => []
  }, $class;

  $self->{mmap} = _mmap($self->{file});
  return $self;
};


# Add a postings list to lift
sub add {
  my ($self, $info) = @_;

  # $term_id, $start, $length, $freq
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

      # Initialize the postings list
      # TODO:
      #   Use a store version
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
