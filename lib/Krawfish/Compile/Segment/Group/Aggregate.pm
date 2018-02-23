package Krawfish::Compile::Segment::Group::Aggregate;
use strict;
use warnings;
use Krawfish::Compile::Query::Nowhere;
use Role::Tiny::With;

with 'Krawfish::Compile::Segment';

use constant DEBUG;

# Aggregate values of groups per document and per match

# Add per group values from fields,
# like in a group on documents add the min and max values
# of a field, e.g. the date span, or the total number
# of sentences in a corpus.

# This, of course, is sometimes in use limited to docGroups
# and makes no sense for matchGroups.


sub new {
  my $class = shift;

  my $self = bless {
    ops   => shift,
    last_doc_id => -1,
    finished    => 0
  }, $class;

  $self->_init_operations;

  return $self;
};


# Initialize aggregation operations
# TODO:
#   This is shared with Segment::Agregate
sub _init_operations {
  my $self = shift;

  # The aggregation needs to trigger on each match
  my (@each_doc, @each_match);
  foreach my $op (@{$self->{ops}}) {
    if ($op->can('each_match')) {
      push @each_match, $op;
    };

    # The aggregation needs to trigger on each doc
    if ($op->can('each_doc')) {
      push @each_doc, $op;
    };
  };

  $self->{each_doc}   = \@each_doc;
  $self->{each_match} = \@each_match;
};


# Increment aggregation on document for a group pattern
sub each_doc {
  my ($self, $current, $pattern) = shift;
  foreach ($self->{each_doc}) {
    $_->each_doc($current, $pattern);
  };
};


# Increment aggregation on match for a group pattern
sub each_match {
  my ($self, $current, $pattern) = shift;
  foreach ($self->{each_match}) {
    $_->each_match($current, $pattern);
  };
};


# Clone object
sub clone {
  my $self = shift;
  my $op_clones = [map { $_->clone } @{$self->operations}];
  __PACKAGE__->new(
    $op_clones
  );
};


# Get operations
sub operations {
  $_[0]->{ops};
};


# stringification
sub to_string {
  my $self = shift;
  my $str = 'groupAggr(';
  $str .= '[' . join(',', map { $_->to_string } @{$self->{ops}}) . ']';
  return $str . ')';
};



1;
