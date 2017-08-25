package Krawfish::Index::Fields::Ranks;
use Krawfish::Index::Fields::Rank;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless {}, $class;
};

# Get the rank by
sub by {
  my ($self, $field_id) = @_;

  # Field may be ranked or not
  return $self->{$field_id};
};

sub introduce_rank {
  my ($self, $field_id, $collation) = @_;
  $self->{$field_id} = Krawfish::Index::Fields::Rank->new($collation);
};


1;
