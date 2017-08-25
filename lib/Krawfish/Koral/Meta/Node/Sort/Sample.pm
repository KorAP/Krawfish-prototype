package Krawfish::Koral::Meta::Node::Sort::Sample;
use Krawfish::Result::Segment::Sort::Sample;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless {
    query => shift,
    top_k => shift
  }, $class;
};

sub type {
  'sample'
};

# Set or get the top_k limitation!
sub top_k {
  my $self = shift;
  if (defined $_[0]) {
    $self->{top_k} = shift;
    return $self;
  };
  return $self->{top_k};
};



sub identify {
  my ($self, $dict) = @_;

  $self->{query} = $self->{query}->identify($dict);

  return $self;
};


sub optimize {
  my ($self, $segment) = @_;

  my $query = $self->{query}->optimize($segment);

  if ($query->max_freq == 0) {
    return Krawfish::Query::Nothing->new;
  };

  return Krawfish::Result::Segment::Sort::Sample->new(
    $query,
    $self->{top_k}
  )
};


sub to_string {
  return 'sample(' . $_[0]->{top_k} . ':' . $_[0]->{query}->to_string . ')';
};

1;
