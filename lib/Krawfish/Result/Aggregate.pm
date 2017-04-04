package Krawfish::Result::Aggregate;
use parent 'Krawfish::Result';
use Hash::Merge qw( merge );
use strict;
use warnings;

use constant DEBUG => 0;

# TODO:
#   See https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations.html

# TODO:
#   Aggregates should be sortable either <asc> or <desc>,
#   and should have a count limitation, may be even a start_index and an items_per_page


# TODO: Sort all ops for each_match and each_doc support
sub new {
  my $class = shift;
  return bless {
    last_doc_id => -1,
    query => shift,
    ops => shift,
    last_doc_id => -1
  }, $class;
};


sub next {
  my $self = shift;
  if ($self->{query}->next) {
    my $current = $self->{query}->current;

    if ($current->doc_id != $self->{last_doc_id}) {

      # Collect data of current operation
      foreach (@{$self->{ops}}) {
        $_->each_doc($current);
      };

      # Set last doc to current doc
      $self->{last_doc_id} = $current->doc_id;
    };

    # Collect data of current operation
    foreach (@{$self->{ops}}) {
      $_->each_match($current);
    };

    return 1;
  };

  return 0;
};


sub current {
  return $_[0]->{query}->current;
};

sub result {
  my $self = shift;
  my $hash = {};
  foreach my $op (@{$self->{ops}}) {
    $hash = merge($hash, $op->result);
  };
  return $hash;
};

sub to_string {
  my $self = shift;
  my $str = 'aggregate(';
  $str .= '[' . join(',', map { $_->to_string } @{$self->{ops}}) . ']:';
  $str .= $self->{query}->to_string;
  return $str . ')';
};

sub finish {
  while ($_[0]->next) {};
  return 1;
};

1;
