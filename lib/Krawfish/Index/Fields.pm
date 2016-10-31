package Krawfish::Index::Fields;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless {
    file => shift,
    array => []
  }, $class;
};

sub store {
  my $self = shift;
  my $doc_id = shift;
  my ($key, $value) = @_;
  my $fields = ($self->{array}->[$doc_id] //= {});
  $fields->{$key} = $value;
};

sub get {
  my $self = shift;
  my $doc_id = shift;
  my $doc = $self->{array}->[$doc_id];
  return $doc->{$_[0]} if @_;
  return $doc;
};

1;
