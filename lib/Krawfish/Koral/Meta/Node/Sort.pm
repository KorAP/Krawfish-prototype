package Krawfish::Koral::Meta::Node::Sort;
use Krawfish::Query::Nowhere;
use Krawfish::Log;
use strict;
use warnings;

use constant (
  DEBUG => 1,
  UNIQUE => 'id'
);

sub new {
  my $class = shift;

  if (DEBUG) {
    print_log(
      'kq_n_sort', 'Create sort query with ' .
        join(', ', map {$_ ? $_ : '?'} @_)
      );
  };

  my $self = bless {
    query  => shift,
    sort   => shift,
    top_k  => shift,
    filter => shift
  }, $class;
};


sub type {
  'sort';
};


# Get identifiers
sub identify {
  my ($self, $dict) = @_;

  my @identifier;
  foreach (@{$self->{sort}}) {

    # Criterion may not exist in dictionary
    my $criterion = $_->identify($dict);
    if ($criterion) {
      push @identifier, $criterion;
    };
  };

  $self->{query} = $self->{query}->identify($dict);

  # Do not sort
  if (@identifier == 0) {
    warn 'There is currently no sorting defined';
    return $self->{query};
  };

  $self->{sort} = \@identifier;
  return $self;
};


# Stringification
sub to_string {
  my $self = shift;
  my $str = join(',', map { $_->to_string } @{$self->{sort}});

  if ($self->{top_k}) {
    $str .= ';k=' . $self->{top_k};
  };

  if ($self->{filter}) {
    $str .= ';sortFilter'
  };

  return 'sort(' . $str . ':' . $self->{query}->to_string . ')';
};


# Optimize query for postingslist
sub optimize {
  my ($self, $segment) = @_;

  my $query = $self->{query}->optimize($segment);

  if ($query->max_freq == 0) {
    return Krawfish::Query::Nowhere->new;
  };

  return $self;
};

1;
