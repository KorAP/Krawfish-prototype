package Krawfish::Posting::Match::Fields;
use strict;
use warnings;

# The fields are represented as Krawfish::Koral::Document::Field* objects!

# TODO:
#   All Krawfish::Posting::Match::* objects may be better suited in Koral!

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

sub inflate {
  my $self = shift;
};

1;
