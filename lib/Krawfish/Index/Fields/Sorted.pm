package Krawfish::Index::Fields::Sorted;
use strict;
use warnings;

# TODO:
#   Plain and Sorted should
#   probably be in a single object!

# TODO:
#   Currently the sorted list only contains
#   a list of doc_ids per rank. However - It's
#   more beneficial to store the value as well.


# Constructor
sub new {
  my $class = shift;
  bless [], $class;
};


# Reset list - possibly rename to delete()
sub reset {
  @{$_[0]} = ();
};


# Add new item to list
sub add {
  my ($self, $value, $doc_id) = @_;
  push @$self, [$doc_id];
};


# Add doc id to last item (same rank
sub add_doc_id_to_final {
  my ($self, $doc_id) = @_;
  push @{$self->[-1]}, $doc_id;
};


# Skip to a certain rank
sub skip_to {
  my ($self, $rank) = @_;
  ...
};


# Return the comparation key
# at a certain rank
sub key_for {
  my ($self, $rank) = @_;
  ...
};


# Get the max rank
sub max_rank {
  ...
};


# Stringification
sub to_string {
  my $self = shift;
  return join('', map { '[' . join(',',@$_) . ']' } @$self);
};


# Get list of all doc ids
# This may be replaced with
# get_asc() and get_desc()
sub doc_ids {
  @{$_[0]}
};

1;
