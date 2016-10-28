package Krawfish::QueryBuilder;
use Krawfish::Query::Token;
use Krawfish::Query::Span;
use Krawfish::Query::Next;
use Krawfish::Query::Position;
use strict;
use warnings;

# TODO: Better not expect index object in constructor,
# but support apply() method

sub new {
  my $class = shift;
  my $index = shift;
  bless {
    index => $index
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


sub sequence {
  my $self = shift;
  my ($element1, $element2) = @_;
  return Krawfish::Query::Next->new(
    $element1, $element2
  );

  # TODO: Rewrite to ...
  return Krawfish::Query::Position->new(
    2, $element1, $element2
  );
};

sub position {
  my $self = shift;
  my ($frame_array, $element1, $element2) = @_;
  my $frame = 0b0000_0000_0000_0000;
  foreach (@$frame_array)  {
    if ($_ eq 'precedes_directly') {
      $frame |= 0b0000_0000_0000_0010;
    }
    else {
      warn "Unknown frame title $_!";
    };
  };

  return if $frame == 0b0000_0000_0000_0000;
  return Krawfish::Query::Position->new(
    $frame, $element1, $element2
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

1;
