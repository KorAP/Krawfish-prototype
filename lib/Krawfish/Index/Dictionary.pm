package Krawfish::Index::Dictionary;
use strict;
use warnings;
use Krawfish::Log;
use Krawfish::Index::PostingsList;

# TODO: Use Storable
# TODO: Support case insensitivity

use constant DEBUG => 0;

sub new {
  my $class = shift;
  my $file = shift;
  bless {
    file => $file,
    hash => {},   # Contain the dictionary
    array => [],  # Temporary helper array for term_id -> term mapping
    last_term_id => 1
  }, $class;
};


# Add should return term-id (or term-string)
sub add {
  my $self = shift;
  my $term = shift;
  print_log('dict', "Added term $term") if DEBUG;

  my $hash = $self->{hash};

  # Term not in dictionary yet
  unless (exists $hash->{$term}) {

    # Increment term_id
    # TODO: This may infact fail, as term_ids are limited in size.
    #   For hapax legomena, a special null marker will be returned
    my $term_id = $self->{last_term_id}++;

    # Create new listobject
    $hash->{$term} = Krawfish::Index::PostingsList->new(
      $self->{file}, $term, $term_id
    );

    # Store term for term_id mapping
    $self->{array}->[$term_id] = $term;
  };
  return $hash->{$term};
};

# Return pointer in list
sub pointer {
  my ($self, $term) = @_;
  print_log('dict', 'Try to retrieve pointer ' . $term) if DEBUG;
  my $list = $self->{hash}->{$term} or return;
  return $list->pointer;
};


# Return the term from a term_id
# This needs to be fast (can't be done like this)
sub term_by_term_id {
  my ($self, $term_id) = @_;
  print_log('dict', 'Try to retrieve id ' . $term_id) if DEBUG;
  return $self->{array}->[$term_id];
};


# Returns the term id by a term
# Currently this is a bit complicated to the the round trip
# Using the list
sub term_id_by_term {
  my ($self, $term) = @_;
  print_log('dict', 'Try to retrieve term ' . $term) if DEBUG;
  my $list = $self->{hash}->{$term};
  return $list->term_id if $list;
  return;
};

# Return terms of the term dictionary
# TODO: This should return an iterator
sub terms {
  my ($self, $re) = @_;

  if ($re) {
    return sort grep { $_ =~ $re } keys %{$self->{hash}};
  };

  return keys %{$self->{hash}};
};

1;
