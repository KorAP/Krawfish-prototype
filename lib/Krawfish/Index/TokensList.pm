package Krawfish::Index::TokensList;
use strict;
use warnings;

use constant DEBUG => 0;

# This is a special PostingsList to store the length of tokens
# in segments
#
# It may also be used for extensions and distances with tokens
# (instead of segments)
#
# That's why this postingslist has a special API for extensions
# and word distances.
#
# Structure may be: ([docid-delta]([seg-pos-delta][length-varbit])*)*
#
# The problem is, this won't make it possible to go back and forth.

sub new {
  my $class = shift;
  bless {
    array => [],
    pos => -1,
    index_file => shift,
    foundry => shift
  }, $class;
}

sub append {
  my $self = shift;
  my ($token, $doc_id, $pos, $end) = @_;
  print_log('toklist', "Appended $token with $doc_id, $pos" . ($end ? "-$end" : '')) if DEBUG;
  push(@{$self->{array}}, [$doc_id, $pos, $end]);
};

sub next;

sub pos {
  return $_[0]->{pos};
};

sub token {
  return $_[0]->{array}->[$_[0]->pos];
};


sub freq;

sub skip_to_doc;

sub skip_to_pos;


# Get an array of start positions that are in the range of min/max
# Start with the lowest
sub extend_to_left {
  my ($self, $start, $min, $max) = @_;
  # Returns an array of start positions
  ...
};

# Get an array of end positions that are in the range of min/max
# Start with the lowest
sub extend_to_right {
  my ($self, $end, $min, $max) = @_;
  # Returns an array of end positions
  ...
};

# Check if the number of tokens between end and start
# is in the given range.
#
# This is necessary for token distance
# a []{2,3} b
sub check_tokens_between {
  my ($self, $end, $start, $min, $max) = @_;

  # First check if this is even possible based on segments
  # then check on tokens
  ...
}


1;

__END__
