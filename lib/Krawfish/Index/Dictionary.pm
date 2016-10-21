package Krawfish::Index::Dictionary;
use strict;
use warnings;
use Krawfish::Index::PostingsList;

# TODO: Use Storable

sub new {
  my $class = shift;
  my $file = shift;
  bless {
    file => $file,
    hash => {}
  }, $class;
};

sub add {
  my $self = shift;
  my $term = shift;
  my $post_list = $self->{hash}->{$term} //= Krawfish::Index::PostingsList->new(
    $self->{file}, $term
  );
  return $post_list;
};

sub get {
  my ($self, $term) = @_;
  return $self->{hash}->{$term};
};

1;
