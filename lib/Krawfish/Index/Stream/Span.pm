package Krawfish::Index::Stream::Span;
use parent 'Krawfish::Index::Stream';
use Krawfish::Posting::Token;
use strict;
use warnings;

# This is a PostingsList-Example for Spans

# Add entry to bitstream
sub add {
  my $self = shift;

  # Add doc id
  my $doc_id = shift;
  my $last_doc_id = $self->{delta}->[0] // 0;
  $self->add_vint($doc_id - $last_doc_id); # Add delta
  $self->{delta}->[0] = $doc_id;

  # Add position
  my $pos = shift;

  # Position in the same doc
  if ($doc_id == $last_doc_id) {

    # Get delta
    my $last_pos = $self->{delta}->[1] // 0;
    $self->{delta}->[1] = $pos;
    $pos -= $last_pos;
  }

  # Initial position in doc
  else {
    $self->{delta}->[1] = $pos;
  };

  my $end = shift;
  my $depth = shift // 0;

  # Add bytes
  $self->add_simple_16(
    $pos,
    $end - $pos,
    $depth
  );

  $self->{freq}++;
  return $self;
};


# Use finger for offset and deltas
sub get {
  my ($self, $finger) = @_;
  my $offset = $finger->offset;

  my @return;

  # Get doc id
  ($offset, my $doc_id_delta) = $self->get_vint($offset);
  my $doc_id = $finger->delta->[0] // 0;

  push @return, ($doc_id + $doc_id_delta);
  $finger->delta->[0] = $doc_id + $doc_id_delta;

  ($offset, my $pos_delta, my $end_delta, my $depth) = $self->get_simple_16($offset);

  # Get position - may be delta
  my $pos = $finger->delta->[2] // 0;
  if ($doc_id_delta == 0) {
    $pos += $pos_delta;
  }
  else {
    $pos = $pos_delta;
  };

  # set delta
  $finger->delta->[2] = $pos;

  $finger->offset($offset);

  # Return values
  return [@return, $pos, $pos + $end_delta, $depth];
};


sub posting {
  shift;
  return Krawfish::Posting::Token->new(@_);
};


1;
