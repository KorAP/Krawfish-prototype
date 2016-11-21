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

# Return pointer
sub get {
  my ($self, $term) = @_;
  my $list = $self->{hash}->{$term} or return;
  return $list->pointer;
};

# Return terms of the term dictionary
sub terms {
  my ($self, $re) = @_;

  if ($re) {
    return sort grep { $_ =~ $re } keys %{$self->{hash}};
  };

  return keys %{$self->{hash}};
};

1;
