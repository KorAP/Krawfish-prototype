package Krawfish::Koral::Builder;
use Krawfish::Query::Token;
use Krawfish::Query::Span;
use Krawfish::Query::Position;
use strict;
use warnings;

# This is now irrelevant due to Krawfish::Koral::Query

sub new {
  my $class = shift;
  bless {
    index => shift
  }, $class;
};

sub token {
  my $self = shift;
  my $term = shift;
  return Krawfish::Query::Token->new(
    $self->{index},
    $term
  );
};

sub span {
  my $self = shift;
  my $term = shift;
  return Krawfish::Query::Span->new(
    $self->{index},
    $term
  );
};


# Create token group
sub token_and {
  my $self = shift;
  my ($span_a, $span_b) = @_;
  return Krawfish::Query::Position->new(
    'matches', $span_a, $span_b
  );
};

# Create sequence query
sub sequence {
  my $self = shift;
  my ($span_a, $span_b) = @_;

  return $self->position(
    'precedes_directly', $span_a, $span_b
  );
};

# Create simple positional query
sub position {
  my $self = shift;
  my ($frame_array, $span_a, $span_b) = @_;

  # check frame array
  my $frame = _frame($frame_array);

  # Do not support empty array
  return if $frame == 0b0000_0000_0000_0000;

  return Krawfish::Query::Position->new(
    $frame, $span_a, $span_b
  );
};

sub position_exclude {
  my $self = shift;
  my ($frame_array, $span_a, $span_b) = @_;

  # check frame array
  my $frame = _frame($frame_array);

  # Do not support empty array
  return if $frame == 0b0000_0000_0000_0000;

  return Krawfish::Query::Position->new(
    ~$frame, $span_a, $span_b
  );
};

sub sort_by {
  my $self = shift;
  my $field = shift;
  # This will walk through the term dictionary
  # Using the field prefix in order
  # And use the doc_ids to intersect with the matching list
  # For this, the Match may first be converted to
  # a bitstream of documents
  ...
};

sub apply {
  ...
};


# TODO: Should be exported, so not necessary
sub _frame ($) {
  my $array = shift;

  my $frame = 0b0000_0000_0000_0000;

  # Reference array
  $array = ref $array eq 'ARRAY' ? $array : [$array];

  # Iterate over all frames
  foreach (@$array) {

    # Check parameter
    if ($_ eq 'precedes_directly') {
      $frame |= 0b0000_0000_0000_0010;
    }
    elsif ($_ eq 'matches') {
      $frame |= 0b0000_0000_0010_0000;
    }
    else {
      warn "Unknown frame title $_!";
    };
  };

  return $frame;
};


1;
