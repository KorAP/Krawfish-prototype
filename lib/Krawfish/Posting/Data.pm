package Krawfish::Posting::Data;
use overload '""' => sub { $_[0]->to_string }, fallback => 1;
use strict;
use warnings;

# Represent arbitrary posting data, that may be cast to
# other posting types


# Constructor
sub new {
  my ($class, $data) = @_;
  bless [@$data], $class;
};


# Document id in posting
sub doc_id {
  $_[0]->[0];
};


# Stringification
sub to_string {
  my $self = shift;
  my $str = '[' . $self->doc_id;
  $str .= $self->[1] ? '$' . join(',',@{$self}[1..$#{$self}]) : '';
  return $str . ']';
};


1;
