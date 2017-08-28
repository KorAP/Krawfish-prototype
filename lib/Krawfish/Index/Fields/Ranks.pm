package Krawfish::Index::Fields::Ranks;
use Krawfish::Index::Fields::Rank;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 1;

# TODO:
#   Instead of 'by()', implement
#   'ascending()' and 'descending()!'
#   And store the information, if a field
#   has multiple values in the ranks overfiew



sub new {
  my $class = shift;

  # Should have the structure:
  # { field_id => [asc_rank, desc_rank?] }
  # If desc_rank is undefined, get the
  # asc_rank for descending values and calculate
  # using max_rank
  bless {}, $class;
};

# Get the rank by
# TODO: DEPRECATED
sub by {
  my ($self, $field_id) = @_;

  # Field may be ranked or not
  return $self->{$field_id};
};


# Get ascending rank
sub ascending {
  my ($self, $field_id) = @_;
  ...
};


# Get descending rank
sub descending {
  my ($self, $field_id) = @_;
  ...
};

# Introduce rank for a certain field
sub introduce_rank {
  my ($self, $field_id, $collation) = @_;

  if (DEBUG) {
    print_log('f_ranks', 'Introduce rank for field ' . $field_id .
                ' with collation ' . $collation);
  };

  $self->{$field_id} = Krawfish::Index::Fields::Rank->new($collation);
};


# Commit uncommitted data
sub commit {
  my $self = shift;

  if (DEBUG) {
    print_log('f_ranks', 'Commit ranks');
  };

  # This can eventually be parallelized
  $_->commit foreach values %$self;

  return 1;
};

sub to_string {
  my $self = shift;
  return join(';', map { $_ . ':' . $self->{$_}->to_string } keys %$self);
};

1;
