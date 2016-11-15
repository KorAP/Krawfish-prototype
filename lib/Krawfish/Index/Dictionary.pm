package Krawfish::Index::Dictionary;
use strict;
use warnings;
use Krawfish::Log;
use Krawfish::Index::PostingsList;

# TODO: Use Storable
use constant DEBUG => 0;

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
  print_log('dict', "Added term $term") if DEBUG;
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
