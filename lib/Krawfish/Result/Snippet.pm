package Krawfish::Result::Snippet;
use parent 'Krawfish::Result';
use Krawfish::Result::Snippet::Highlights;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 1;

# TODO:
#  - ExpandToSpan
#  - Context with chars and tokens

sub new {
  my $class = shift;
  my %param = @_;

  my $self = bless {
    query => $param{query},
    index => $param{index}
  }, $class;

  $self->{subtokens} = $self->{index}->subtokens;

  # Create highlight object
  $self->{highlights} = Krawfish::Result::Snippet::Highlights->new(
    $param{highlights},
    $self->{subtokens}
  );

  return $self;
};


# Iterated through the ordered linked list
sub next {
  my $self = shift;
  $self->{match} = undef;
#  $self->{highlights}->clear;
  return $self->{query}->next;
};


sub current_match {
  my $self = shift;

  print_log('c_snippet', 'Get current match') if DEBUG;

  # Match is already set
  return $self->{match} if $self->{match};

  # Get current match from query
  my $match = $self->match_from_query;

  print_log('c_snippet', 'match is' . $match) if DEBUG;

  my $pd = $self->{index}->primary->get(
    $match->doc_id,
    0,
    500
  ) // '';

  # TODO: $highlights

  $match->fields({snippet => $pd});

  $self->{match} = $match;
  return $match;
};

sub to_string {
  my $self = shift;
  my $str = 'collectSnippet(';
  $str .= $self->{query}->to_string;
  return $str . ')';
};

# From Mojo::Util
sub _squote {
  my $str = shift;
  $str =~ s/(['\\])/\\$1/g;
  return qq{'$str'};
};


1;
