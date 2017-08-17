package Krawfish::Posting::Match::Fields;
use strict;
use warnings;

# The fields are represented as Krawfish::Koral::Document::Field* objects!

sub new {
  my $class = shift;
  bless {
    fields => [@_]
  }, $class;
};

sub to_string {
  my $self = shift;
  return 'fields:' . join(',', map { $_->to_string } @{$self->{fields}});
};

1;
