package Krawfish::Index::Fields::Direction;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 1;

sub new {
  my $class = shift;
  my $list = shift;
  bless $list, $class;
};

sub rank_for {
  my ($self, $doc_id) = @_;

  if (DEBUG) {
    print_log(
      'f_rank_dir',
      'Get rank for doc ' . $doc_id . ' which is ' . $self->[$doc_id]
    );
  };

  return $self->[$doc_id] // 0;
};


# TODO:
#   May be implemented more efficiently
sub rank_if_lt_for {
  my ($self, $doc_id, $value) = @_;
  my $rank = $self->[$doc_id];
  return 0 unless $rank;
  return $rank < $value ? $rank : 0;
};

1;
