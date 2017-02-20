package Krawfish::Koral::Meta::Sort;
use strict;
use warnings;
use Krawfish::Log;
use Krawfish::Result::Sort;

use constant DEBUG => 0;

# TODO: Should differ between
# - sort_by_fields()
# and
# - sort_by_class()

# fields => [[asc => 'author', desc => 'title']]
sub new {
  my $class = shift;
  my $query = shift;
  my @fields = @_;
  bless {
    query => $query,
    fields => \@fields,
    filterable => 0
  }, $class;
};


# Sorting can be optimized by an appended filter, in case there is no need
# for counting all matches and documents.
#
# This can be added to the query using
# ->filter_by($sort->filter)
sub filter {
  my $self = @_;

  # The filter should be disabled, because all matches need to be counted!
  if (defined $_[0]) {
    $self->{filterable} = shift;
    return;
  };

  # Filter is disabled
  return unless $self->{filterable};

  # return Krawfish::Result::Sort::Filter->new(
  #   $self->{corpus}
  # );
  ...
};


sub plan_for {
  my ($self, $index) = @_;

  my $field = shift @{$self->{fields}};

  # TODO: Sorting should simply use
  # Krawfish::Result::Sort and the passes
  # should be handled there!

  # Initially sort using bucket sort
  $query = Krawfish::Result::Sort::FirstPass->new(
    $self->{query},
    ($field->[0] eq 'desc' ? 1 : 0),
    $field->[1]
  );

  # Iterate over all fields
  foreach $field (@{$self->{fields}}) {
    $query = Krawfish::Result::Sort::Rank->new(
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
