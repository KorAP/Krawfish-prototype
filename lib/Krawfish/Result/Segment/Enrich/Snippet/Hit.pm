package Krawfish::Result::Segment::Enrich::Snippet::Hit;
use Krawfish::Koral::Document::Subtoken;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 1;

sub new {
  my $class = shift;
  bless {
    @_
  }, $class;
};

sub content {
  my ($self, $match, $forward) = @_;

  if ($match->start != $forward->pos) {
    warn 'The current position is not at the start position of the match';
    return;
  };

  my @data;
  my $length = $match->end - $match->start;
  while ($length > 0) {

    # Get the current token
    my $current = $forward->current;

    # Add token to text
    push @data, Krawfish::Koral::Document::Subtoken->new_by_term_id(
      $current->preceding_data,
      $current->term_id
    );

    # Get the surface data
    $length--;
    $forward->next or last;
  };

  if (DEBUG) {
    print_log('c_snippet', 'Add snippet match data: ' . join(',', @data));
  };

  return \@data;
};

sub to_string {
  'hit';
};


1;
