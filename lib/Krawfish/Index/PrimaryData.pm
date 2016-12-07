package Krawfish::Index::PrimaryData;
use strict;
use warnings;

# TODO: Add text compression with random access
# e.g. based on http://www.unicode.org/notes/tn31/

sub new {
  my $class = shift;
  bless {
    file => shift,
    primary => []
  }, $class;
};

sub store {
  my $self = shift;
  my ($doc_id, $text) = @_;
  $self->{primary}->[$doc_id] = $text;
};

sub get {
  my $self = shift;
  my ($doc_id, $start, $end) = @_;
  return substr($self->{primary}->[$doc_id], $start, $end - $start);
};

1;
