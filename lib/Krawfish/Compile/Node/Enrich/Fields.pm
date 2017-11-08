package Krawfish::Compile::Node::Enrich::Fields;
use Krawfish::Util::String qw/squote/;
use strict;
use warnings;

# Koral::Node::Fields does actually nothing.
# It's just a wrapper.
# However - it may very well - like snippets - first
# collect matches and then resend request to the
# cluster for more information.

# TODO:
#   Fields should be part of the snippet generation mechanism!

# TODO:
#   Inflate on the enrichments!

sub new {
  my $class = shift;
  bless {
    query => shift,
    fields => shift
  }, $class;
};


# Stringification
sub to_string {
  my $self = shift;
  return 'fields(' . join(',', map { $_->to_string } @{$self->{fields}}) .
    ':' . $self->{query}->to_string . ')';
};


# Move to next posting
sub next {
  $_[0]->{query}->next;
};


1;
