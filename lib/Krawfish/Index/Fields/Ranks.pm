package Krawfish::Index::Fields::Ranks;
use Krawfish::Index::Fields::Rank;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 1;

# TODO:
#   Instead of 'by()', implement
#   'ascending()' and 'descending()!'


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


# Introduce rank for a certain field
sub introduce_rank {
  my ($self, $field_id, $collation) = @_;

  if (DEBUG) {
    print_log('f_ranks', 'Introduce rank for field ' . $field_id);
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
