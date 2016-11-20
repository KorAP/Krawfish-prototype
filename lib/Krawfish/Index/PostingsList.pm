package Krawfish::Index::PostingsList;
use Krawfish::Index::PostingPointer;
use strict;
use warnings;
use constant DEBUG => 0;

# TODO: Use different PostingsList for different term types
# TODO: Split postinglists, so they have different sizes,
# that may be fragmented.

sub new {
  my ($class, $index, $term) = @_;
  bless {
    term => $term,
    index => $index,
    array => [],
    pointers => []
  }, $class;
};

sub append {
  my $self = shift;
  my ($doc_id, $pos, @payload) = @_;
  print_log('post', "Appended " . $self->term . " with $doc_id, $pos") if DEBUG;
  push (@{$self->{array}}, [$doc_id, $pos, @payload]);
};

sub freq {
  return scalar @{$_[0]->{array}};
};

sub term {
  return $_[0]->{term};
};

sub at {
  return $_[0]->{array}->[$_[1]];
};

sub pointer {
  my $self = shift;
  # TODO: Add pointer to pointer list
  # so the PostingsList knows, which fragments to lift
  # Be aware, this may result in circular structures
  Krawfish::Index::PostingPointer->new($self);
};

1;

__END__




