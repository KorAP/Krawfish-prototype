package Krawfish::Koral::Compile::Enrich::CorpusClasses;
use Krawfish::Koral::Compile::Node::Enrich::CorpusClasses;
use List::MoreUtils qw/uniq/;
use strict;
use warnings;

# Mark a match if it is part of a corpus class.
# This can be used for comparing different classes,
# but also for marking special matches, e.g.
# when a VC has a certain index constraint (<= 2020-08-09)
# an addition like
# "and (lastModified lte 2020-08-09 | {16:lastModified gt 2020-08-09}"
# can flag all texts that were modified after the date, but indexed before.

sub new {
  my $class = shift;
  bless [@_], $class;
}

sub type {
  'corpusclasses'
};


# Get or set operations
sub operations {
  my $self = shift;
  if (@_) {
    @$self = @_;
    return $self;
  };
  return @$self;
};


# Remove duplicates
sub normalize {
  my $self = shift;
  @$self = uniq @$self;
  return $self;
};


# Create a single query tree
sub wrap {
  my ($self, $query) = @_;
  return Krawfish::Koral::Compile::Node::Enrich::CorpusClasses->new(
    $query,
    [$self->operations]
  );
};


sub to_string {
  my $self = shift;
  return 'corpusclasses:[' . join(',', @$self) . ']';
};

1;
