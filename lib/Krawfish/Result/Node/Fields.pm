package Krawfish::Result::Node::Fields;
use parent 'Krawfish::Query';
use Krawfish::Util::String qw/squote/;
use strict;
use warnings;

# Koral::Node::Fields does actually nothing. It's just a wrapper
# However - it may very well - like snippets - first collect matches and
# then resend request to the cluster for more information,
# like

# TODO:
#   Fields should be part of the snippet generation mechanism!

sub new {
  my $class = shift;
  bless {
    query => shift,
    fields => shift
  }, $class;
};

sub to_string {
  my $self = shift;
  return 'fields(' . join(',', map { squote($_) } @{$self->{fields}}) . ':' . $self->{query}->to_string . ')';
};

sub next {
  $_[0]->{query}->next;
};

1;
