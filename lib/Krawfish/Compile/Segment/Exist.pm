package Krawfish::Compile::Segment::Exist;
use strict;
use warnings;
use Role::Tiny;

with 'Krawfish::Compile::Segment';


# Check, if a certain query results in at least one single
# posting.

# This is useful to check if a certain VC exists, e.g. if a VC
# is accessible or altered after a rewrite.

# Constructor
sub new {
  my $class = shift;
  bless {
    query => shift,
    exists => undef
  }, $class;
};


# Get the collection
# TODO:
#   Rename to compilation
sub collection {
  my $self = shift;
  return {
    exists => $self->{exists}
  };
};


# Recursively add all results to the result page
sub collect {
  my ($self, $result) = @_;

  $result->add_collection($self->collection);

  $self->{query}->collect($result);

  return $result;
};


# Move to next posting
sub next {
  my $self = shift;

  return undef if defined $self->{exists};

  if ($self->{query}->next) {
    $self->{exists} = 1;
    $self->{query}->close;
    return 1;
  };

  $self->{exists} = 0;
  $self->{query}->close;
  return;
};


# Delegate current posting retrieval
sub current {
  $_[0]->{query}->current;
};


# Stringification
sub to_string {
  my $self = shift;
  return 'exists(' . $self->{query}->to_string . ')';
};


1;
