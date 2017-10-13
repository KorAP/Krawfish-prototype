package Krawfish::Index::PostingsList;
use Krawfish::Index::PostingPointer;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

# TODO:
#   Per segment has the information of frequency, length,
#   and position in segment.

# TODO:
#   Check if there is a relation to Posting::List.

# TODO:
#   Use different PostingsList (or rather different PostingPointer)
#   for different term types

# TODO:
#   Split postinglists, so they have different sizes,
#   that may be fragmented.

# TODO:
#   Return K::P::Data for at()

# Constructor
sub new {
  my ($class, $index_file, $term_id) = @_;

  bless {
    term_id => $term_id,
    index_file => $index_file,
    array => [],
    pointers => []
  }, $class;
};


# Add term data to array
# This may need to be done in a bunch per doc
# to be able to set tf
sub append {
  my $self = shift;
  my (@data) = @_;
  if (DEBUG) {
    print_log(
      'post',
      "Appended term_id " . $self->term_id . " with " . join(',', @data)
    );
  };
  push (@{$self->{array}}, [@data]);
};


# Number of all postings in the index
sub freq {
  return scalar @{$_[0]->{array}};
};


# Get term_id associated to the term id
sub term_id {
  return $_[0]->{term_id};
};


# Get item at certain position
# TODO:
#   maybe rename to item(), see Posting::Bundle
sub at {
  return $_[0]->{array}->[$_[1]];
};


# Get new pointer
sub pointer {
  my $self = shift;
  # TODO:
  #   Add pointer to pointer list
  #   so the PostingsList knows, which fragments to lift
  #   Be aware, this may result in circular structures
  Krawfish::Index::PostingPointer->new($self);
};


# Stringification
sub to_string {
  my $self = shift;
  join(',', map { '[' . $_ . ']' } @{$self->{array}});
};


1;

__END__




