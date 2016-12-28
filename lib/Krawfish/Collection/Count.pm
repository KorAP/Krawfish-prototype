package Krawfish::Collection::Count;
use parent 'Krawfish::Collection';
use strict;
use warnings;

# This will calculate the count
# This expects a sorted stream by doc_id

sub new {
  my $class = shift;
  bless {
    query    => shift,
    doc_freq => 0,
    freq     => 0,
    doc_id   => undef
  }, $class;
};


# This may be either a corpus query or a doc query
sub next {
  my $self = shift;

  # Get next item
  if ($self->{query}->next) {

    # Get current posting doc_id
    my $doc_id = $self->{query}->current->doc_id;

    # Document is new
    if (!defined($self->{doc_id}) || ($self->{doc_id} != $doc_id)) {

      # Increment document frequency
      $self->{doc_freq}++;
    };

    # Increment occurrence frequency
    $self->{freq}++;

    # Set last id
    $self->{doc_id} = $doc_id;
    return 1;
  };

  return;
};


sub current {
  return $_[0]->{query}->current;
};


# Return the count frequencies
sub frequencies {
  my $self = shift;
  return ($self->{doc_freq}, $self->{freq});
};


# TODO: Optimize
sub finish {
  my $self = shift;
  while ($self->next) { };
  return 1;
};

sub to_string {
  my $self = shift;
  my $str = 'collectCounts(';
  $str .= $self->{query}->to_string;
  return $str . ')';
};

1;
