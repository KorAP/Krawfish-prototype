package Krawfish::Compile::Segment::Aggregate::Frequencies;
use parent 'Krawfish::Compile::Segment::Aggregate::Base';
use Krawfish::Koral::Result::Aggregate::Frequencies;
use Krawfish::Log;
use strict;
use warnings;

# Count the frequencies of all matches of the query
# per doc and per match

# TODO:
#   Support virtual corpus classes
#   This is especially relevant for measuring the
#   difference between a non-rewritten and a rewritten VC
#   This requires a simple datastructure
#   [class0-totalresources|class0-totalResults][...]

sub new {
  my $class = shift;
  bless {
    flags => shift,
    aggregation => Krawfish::Koral::Result::Aggregate::Frequencies->new
  }, $class;
};

# Add to totalResources immediately
sub each_doc {
  $_[2]->{totalResources}++;

  return;

  # New: Increment for classes
  my ($self, $current) = @_;

  # TODO:
  #   Iterate over valid classes
  foreach ($current->flags_list($self->{flags})) {
    $self->{aggregation}->incr_doc($_);
  };
};


# Add to totalResults immediately
sub each_match {
  $_[2]->{totalResults}++;

  return;

  # New: Increment for classes
  my ($self, $current) = @_;

  # TODO:
  #   Iterate over valid classes
  foreach ($current->flags_list($self->{flags})) {
    $self->{aggregation}->incr_match($_);
  };
};


# Stringification
sub to_string {
  'freq'
};

1;

