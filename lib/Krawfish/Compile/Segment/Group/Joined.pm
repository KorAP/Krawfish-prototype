package Krawfish::Compile::Segment::Group::Joined;
use Krawfish::Koral::Result::Group::Fields;
use Krawfish::Util::Constants qw/NOMOREDOCS/;
use Krawfish::Log;
use strict;
use warnings;
use Role::Tiny::With;

with 'Krawfish::Compile::Segment::Group';

use constant DEBUG => 0;

# This will group matches based on various criteria like
# - fields

# TODO:
#   Maybe instead of raw fields it would be beneficial to have
#   functions like
#   intFunc(XY, 'field')
#     - cluster all dates, like age into categories like 10-19
#     - round all values ...
#   dateFunc(XY, 'field')
#     - trim to years
#     - trim to decades
#     - transfer to days of the week
#   strFunc(XY, 'field')
#     - substring to the first character
#     - fold case


sub new {
  my $class = shift;

  my $self = bless {
    criteria => shift,
    query => shift,
    aggr => shift,

    last_doc_id => -1,
    finished => 0
  }, $class;

  # Initialize group object
  # TODO:
  #   This should use a specialized group object
  $self->{group} = Krawfish::Koral::Result::Group::Fields->new($self->{field_keys});

  return $self;
};

# The Aggregation object is of type Group::Aggregate
sub aggregation {
  my ($self, $aggr) = @_;
  if ($aggr) {
    $self->{aggr} = $aggr;
    return $self;
  };
  return $self->{aggr};
};

# Clone query
sub clone {
  my $self = shift;
  return __PACKAGE__->new(
    $self->{criteria}->clone,
    $self->{query},
    $self->{aggr} ? $self->{aggr}->clone : undef
  );
};

# Initialize pointers
sub _init {
};

# Stringification
sub to_string {
  my ($self, $id) = @_;

  my $str = 'group(';
  $str .= join(',', map { $_->to_string($id) } @{$self->{criteria}});

  if ($self->{aggr}) {
    $str .= ';'. $self->{aggr}->to_string;
  };

  $str .= ':' . $self->{query}->to_string($id) . ')';
  return $str;
};

sub next {
  my $self = shift;

  $self->_init;

  my $criteria = $self->{criteria};

  # There is a next match
  if ($self->{query}->next) {

    # Get the current posting
    my $current = $self->{query}->current;

    my $pattern = [];

    foreach (@$criteria) {
      $criteria->group($current, $pattern)
    }
  };

  # Release on_finish event
  unless ($self->{finished}) {
    $self->group->on_finish;
    $self->{finished} = 1;
  };

  return 0;
};
