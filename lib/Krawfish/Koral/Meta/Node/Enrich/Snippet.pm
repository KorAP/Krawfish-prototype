package Krawfish::Koral::Meta::Node::Enrich::Snippet;
use Krawfish::Util::String qw/squote/;
use strict;
use warnings;

# TODO:
#   Inflate on the enrichments!

sub new {
  my $class = shift;
  bless {
    query => shift,
    options => shift
  }, $class;
};


sub to_string {
  my $self = shift;
  return 'snippet(?:' . $self->{query}->to_string . ')';
};


sub identify {
  my ($self, $dict) = @_;

  $self->{query} = $self->{query}->identify($dict);

  return $self;
};


1;
