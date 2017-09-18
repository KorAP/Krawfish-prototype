package Krawfish::Result::Segment::Enrich::Snippet;
use parent 'Krawfish::Result';
use Krawfish::Posting::Match::Snippet;
# use Krawfish::Result::Segment::Enrich::Snippet::Highlights;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 1;

# TODO:
#  - ExpandToSpan
#  - Context with chars and tokens

sub new {
  my $class = shift;
  # my %param = @_;

  # TODO:
  #   Because the forward pointer needs to move
  #   strictly forward, it needs to cache annotations and term_ids
  #   using a forward buffer!

  my $self = bless {
    query => shift,   # $param{query},
    forward => shift, # $param{forward}
    options => shift
  }, $class;

  return $self;
};


# Initialize forward index
sub _init {
  return if $_[0]->{_init}++;

  my $self = shift;
  $self->{fwd_pointer} = $self->{forward}->pointer;
};


# Iterated through the ordered linked list
sub next {
  my $self = shift;

  $self->_init;

  $self->{match} = undef;
  # $self->{highlights}->clear;
  return $self->{query}->next;
};


# Return the current match
sub current_match {
  my $self = shift;

  print_log('c_snippet', 'Get current match') if DEBUG;

  # Match is already set
  return $self->{match} if $self->{match};

  # Get current match from query
  my $match = $self->match_from_query;

  print_log('c_snippet', 'match is ' . $match) if DEBUG;

  # Get forward query
  my $forward = $self->{fwd_pointer};

  # TODO:
  #   Fetch preceding context

  # This only fetches the match
  # TODO:
  #   fetch annotations as well
  my $doc_id = $match->doc_id;
  if ($forward->skip_doc($doc_id) == $doc_id) {

    if (DEBUG) {
      print_log('c_snippet', 'Move to match doc position');
    };

    if ($forward->skip_pos($match->start)) {

      if (DEBUG) {
        print_log('c_snippet', 'Move to match position');
      };

      my @data;
      my $length = $match->end - $match->start;
      while ($length > 0) {
        my $current = $forward->current;

        # Match is already initiated
        if (@data) {

          # Get the preceding data
          my $pre = $current->preceding_data;

          # Mark as reference (for simplicity)
          push @data, $pre ? \$pre : \'';
        };

        # Get the surface data
        push @data, $current->term_id;
        $length--;
        $forward->next or last;
      };

      if (DEBUG) {
        print_log('c_snippet', 'Add snippet match data: ' . join(',', @data));
      };

      my $snippet = Krawfish::Posting::Match::Snippet->new(
        match_ids => \@data
      );

      # Add snippet to match
      $match->add($snippet);
    };
  };

  # TODO:
  #   Fetch following context

  #  my $pd = $self->{index}->primary->get(
  #    $match->doc_id,
  #    0,
  #    500
  #  ) // '';

  # TODO:
  #   Add highlights

  $self->{match} = $match;
  return $match;
};


# Stringification
sub to_string {
  my $self = shift;
  my $str = 'snippet(';
  $str .= $self->{query}->to_string;
  return $str . ')';
};


1;
