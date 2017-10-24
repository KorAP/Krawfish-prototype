package Krawfish::Koral::Compile::Node::Enrich::CorpusClasses;
use Krawfish::Compile::Segment::Enrich::CorpusClasses;
use Krawfish::Util::Bits;
use Krawfish::Query::Nowhere;
use strict;
use warnings;


# Constructor
sub new {
  my $class = shift;
  bless {
    query => shift,
    classes => shift
  }, $class;
};


# Stringification
sub to_string {
  my ($self, $id) = @_;
  return 'corpusclasses(' . join(',', @{$self->{classes}}) .
    ':' . $self->{query}->to_string($id) . ')';
};


sub identify {
  my ($self, $dict) = @_;

  # Identify query
  $self->{query} = $self->{query}->identify($dict);
  return $self;
};


# Optimize query
sub optimize {
  my ($self, $segment) = @_;

  my $query = $self->{query}->optimize($segment);

  if ($query->max_freq == 0) {
    return Krawfish::Query::Nowhere->new;
  };

  # Create corpus class object
  return Krawfish::Compile::Segment::Enrich::CorpusClasses->new(
    query => $query,
    flags => classes_to_flags(@{$self->{classes}})
  );
};


1;
