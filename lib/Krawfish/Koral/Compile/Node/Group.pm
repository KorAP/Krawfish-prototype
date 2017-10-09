package Krawfish::Koral::Compile::Node::Group;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 1;

warn 'DEPRECATED';


sub new {
  my $class = shift;

  my $self = bless {
    query => shift,
    criterion => shift
  }, $class;
};


# Get identifiers
sub identify {
  my ($self, $dict) = @_;

  $self->{query} = $self->{query}->identify($dict);

  $self->{criterion} = $self->{criterion}->identify($dict);

  # Field to group on is not existent or query matches nowhere
  if (!$self->{criterion} || !$self->{query}) {
    return Krawfish::Koral::Corpus::Nothing->new;
  };

  return $self;

};


sub to_string {
  my $self = shift;
  return 'group(' . $self->{criterion}->to_string . ':' . $self->{query}->to_string . ')';
};


1;
