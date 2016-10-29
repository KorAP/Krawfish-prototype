package Krawfish::Index::PostingsList;
use Krawfish::Posting;
use strict;
use warnings;

# TODO: Use different PostingsList for different term types
# TODO: Split postinglists, so they have different sizes,
#   that may be fragmented.
# TODO: Support filters and skip

sub new {
  my ($class, $index, $term) = @_;
  bless {
    term => $term,
    index => $index,
    array => [],
    pos => -1
  }, $class;
};

sub append {
  my $self = shift;
  my ($doc_id, $pos, @payload) = @_;
  print "  == Appended " . $self->term . " with $doc_id, $pos\n";
  push (@{$self->{array}}, [$doc_id, $pos, @payload]);
};

sub freq {
  return scalar @{$_[0]->{array}};
};

sub term {
  return $_[0]->{term};
};

sub next {
  my $self = shift;
  my $pos = $self->{pos}++;
  return ($pos + 1) < $self->freq ? 1 : 0;
};

sub pos {
  return $_[0]->{pos};
};

sub posting {
  return $_[0]->{array}->[$_[0]->pos];
}

1;

__END__

# sub skip_doc_to;
#sub skip_pos_to;



