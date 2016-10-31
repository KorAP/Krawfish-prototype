package Krawfish::Index::TokensList;
use strict;
use warnings;

# This is a forward index for tokens
# This will be used for complex regular expressions,
# grouping of class results
# and sorting by result characters
#
# It may also be used for extensions and distances with tokens
# (instead of segments)
#
# To efficiently store all tokenizations without redundancy,
# this may be a single token stream with foundry markers, like
#
# [doc_id, token1, token2, [token3a,token3b-4,token3c-4], token4
#
# So if the b foundry was lifted, all tokens are returned as long
# as there is no ambiguity - then the b token is returned.

sub new {
  my $class = shift;
  bless {
    array => [],
    pos => -1,
    foundry => shift
  }, $class;
}

sub append {
  my $self = shift;
  my ($token, $doc_id, $pos, $end) = @_;
  print "  == Appended $token with $doc_id, $pos" . ($end ? "-$end" : '') . "\n";
  push(@{$self->{array}}, [$doc_id, $pos, $end]);
};

sub next;

sub pos {
  return $_[0]->{pos};
};

sub token {
  return $_[0]->{array}->[$_[0]->pos];
}

sub skip_to_doc;

sub skip_to_pos;

1;
