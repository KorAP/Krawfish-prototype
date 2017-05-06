package Krawfish::Posting::Data;
use overload '""' => sub { $_[0]->to_string }, fallback => 1;
use strict;
use warnings;

sub new {
  my ($class, $data) = @_;
  bless [@$data], $class;
};

sub doc_id {
  $_[0]->[0];
};

sub to_string {
  my $self = shift;
  my $str = '[' . $self->doc_id;
  $str .= $self->[1] ? '$' . join(',',@{$self}[1..$#{$self}]) : '';
  return $str . ']';
};

1;
