package Krawfish::Koral::Meta::Node::Sort;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 1;

sub new {
  my $class = shift;

  if (DEBUG) {
    print_log('kq_n_sort', 'Create sort query with ' . join(', ', map {$_ ? $_ : '?'} @_));
  };

  my $self = bless {
    query => shift,
    sort => shift,
    top_k => shift,
    filter => shift
  }, $class;
};


# Get identifiers
sub identify {
  my ($self, $dict) = @_;

  my @identifier;
  foreach (@{$self->{sort}}) {

    # Field may not exist in dictionary
    my $field = $_->identify($dict);
    if ($field) {
      push @identifier, $field;
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


1;
