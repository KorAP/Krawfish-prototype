package Krawfish::Koral::Meta::Sort;
use strict;
use warnings;
use Krawfish::Result::Sort::FirstPass;
use Krawfish::Result::Sort;
use Krawfish::Log;

use constant DEBUG => 0;

# fields => [[asc => 'author', desc => 'title']]
sub new {
  my $class = shift;
  my $query = shift;
  my @fields = @_;
  bless {
    query => $query,
    fields => \@fields
  }, $class;
};

sub plan_for {
  my ($self, $index) = @_;

  my $field = shift @{$self->{fields}};

  # Initially sort using bucket sort
  $query = Krawfish::Result::FilterSort->new(
    $self->{query},
    ($field->[0] eq 'desc' ? 1 : 0),
    $field->[1]
  );

  # Iterate over all fields
  foreach $field (@{$self->{fields}}) {
    $query = Krawfish::Result::RankSort->new(
      $query,
      ($field->[0] eq 'desc' ? 1 : 0),
      $field->[1]
    );
  };

  # Final sorting based on UID
  return Krawfish::Result::Sort->new($query, 0, 'uid');
};


sub type { 'sort' };


sub to_koral_fragment {
  ...
};


sub to_string {
  ...
};


1;
