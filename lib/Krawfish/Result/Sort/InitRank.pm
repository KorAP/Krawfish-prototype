package Krawfish::Result::Sort::InitRank;
use Krawfish::Query::Util::BucketSort;
use strict;
use warnings;

sub new {
  my $class = shift;
  my ($query, $index, $field, $desc) = @_;
  bless {
    field => $field,
  }, $class;
};

sub _init {
  my $self = shift;

  return if $self->{init}++;
};

sub next;

sub current;

# This returns an additional data structure with key/value pairs
# in sorted order to document the sort criteria.
# Like: [[class_1 => 'cba'], [author => 'Goethe']]...
# This is beneficial for the cluster-merge-sort
sub current_sort;

sub to_string {
  my $self = shift;
  my $str = 'bucketSort(';
  $str .= $self->{desc} ? '^' : 'v';
  $str .= ',' . $self->{field} . ':';
  $str .= $self->{query}->to_string;
  return $str . ')';
};
