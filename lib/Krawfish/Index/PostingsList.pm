package Krawfish::Index::PostingsList;
use Krawfish::Index::PostingPointer;
use Krawfish::Log;
use strict;
use warnings;
use constant DEBUG => 0;

# TODO: Use different PostingsList for different term types
#
# TODO: Split postinglists, so they have different sizes,
# that may be fragmented.

sub new {
  my ($class, $index_file, $term, $term_id) = @_;
  bless {
    term => $term,
    term_id => $term_id,
    index_file => $index_file,
    array => [],
    pointers => []
  }, $class;
};

sub append {
  my $self = shift;
  my (@data) = @_;
  if (DEBUG) {
    print_log(
      'post',
      "Appended " . $self->term . " with " . join(',', @data)
    );
  };
  push (@{$self->{array}}, [@data]);
};

sub freq {
  return scalar @{$_[0]->{array}};
};

sub term {
  return $_[0]->{term};
};

sub term_id {
  return $_[0]->{term_id};
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

sub to_string {
  my $self = shift;
  join(',', map { '[' . $_ . ']' } @{$self->{array}});
};


1;

__END__




