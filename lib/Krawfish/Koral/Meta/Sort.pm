package Krawfish::Koral::Meta::Sort;
use strict;
use warnings;
use Krawfish::Log;
use Krawfish::Result::Sort;

# All meta-queries need the nesting query for
# plan_for

use constant DEBUG => 0;

# TODO: Should differ between
# - sort_by_fields()
# and
# - sort_by_class()

# TODO: should support criteria instead
# criteria => [[field => asc => 'author', field =>desc => 'title']]
sub new {
  my $class = shift;
  bless {
    criteria => [@_],
    top_k => undef
  }, $class;
};

sub top_k {
  my $self = shift;
  return $self->{top_k} unless @_;
  $self->{top_k} = shift;
};

# Order sort
sub plan_for {
  my ($self, $index, $query) = @_;
  ...
};


sub type { 'sort' };


sub to_koral_fragment {
  ...
};


# Stringify sort
sub to_string {
  my $self = shift;
  my $str = 'sort(';
  foreach my $criterion (@{$self->{criteria}}) {
    $str .= $criterion->to_string;
  };
  return $str . ')';
};


1;


__END__

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
