package Krawfish::Index::Postings::Coordinator;
use Krawfish::Index::Postings::Lift;
use warnings;
use strict;

# The PostingsCoordinator loads the postings
# index and lifts the relevant postings using buffers

# The index has the structure:
# ([term_id-int][start-offset-int][length-int][freq-int])+

sub new {
  my ($class, $file, $size) = @_;

  # Load 'postings.toc'
  $file = _slurp($file);

  bless {
    file => $file,
    size => $size
  }, $class;
};


# Lift all postingslists from a given list of term ids
sub lift {
  my $self = shift;

  # Expect a sorted list of term ids
  my @term_ids = @_;
  my @to_lift = ();
  my $expected_size = 0;

  my $start_offset = 0;
  foreach (@term_ids) {

    # Search in the file for the term position
    my ($pos, $start, $length, $freq) = $self->_bin_search($_, $start_offset)

      # Set offset to last cursor position
      $start_offset = $pos;

    # Found postingslist for term
    if ($info) {
      push @to_lift, [$term_id, $start, $length, $freq];
      $expected_size += $length
    };
  };

  # TODO:
  #   Calculate the buffer size based on the expected size and the number
  #   of postings lists to lift
  my $buffer_size = $self->{size} / @to_lift;

  # Create lift object and add all postingslists to be lifted to it
  my $lifted = Krawfish::Index::Postings::Lift->new($buffer_size);

  # These will already be sorted
  $lifted->add($_) foreach @to_lift;

  return $lifted;
};


sub _slurp {
  ...
};


sub _bin_search {
  my ($self, $term_id, $start_offset) = @_;

  # Return cursor position
  # and start offset, length and freq
  ...
};


1;
