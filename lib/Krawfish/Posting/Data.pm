package Krawfish::Posting::Data;
use overload '""' => sub { $_[0]->to_string }, fallback => 1;
use Krawfish::Posting::Payload;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless [@_], $class;
};

sub doc_id {
  $_[0]->[0];
};

sub start;

sub end;

sub payload;

sub flags;

1;
