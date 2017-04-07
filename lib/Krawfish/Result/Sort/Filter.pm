package Krawfish::Result::Sort::Filter;
use parent 'Krawfish::Corpus';
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

sub new {
  my $class = shift;
  my %param = @_;

  my $ranking = $param{index}->fields->ranked_by($param{field});
  my $max = $ranking->max if $param{desc};

  bless {
    query        => $param{query},
    max_rank_ref => $param{max_rank_ref},
    field        => $param{field},
    desc         => $param{desc},
    ranking      => $ranking,
    max          => $max,
    init         => 0
  }, $class;
};


# Forward to next document
sub next {
  my $self = shift;

  my $query = $self->{query};

  # Get next document
  while ($query->next) {

    # Check object
    return 1 if $self->_check;
  };

  # No next
  return;
};


# Check the document id for the rank
sub _check {
  my $self = shift;

  # Maximum rank reference
  my $max_rank_ref = $self->{max_rank_ref};

  # Get the current doc_id
  my $query = $self->{query};
  my $current = $query->current;
  my $doc_id = $current->doc_id;

  # Get rank for field
  my $rank = $self->{ranking}->get($doc_id);

  # Invert rank if descending field is required
  $rank = $self->{max} - $rank if $self->{max};

  if (DEBUG) {
    print_log('vc_sort_filter', 'Current posting is ' . $current->to_string);
  };

  # Rank is smaller then required
  if ($rank <= $$max_rank_ref) {

    # Document is fine
    $self->{current} = $current;
    return 1;
  };

  if (DEBUG) {
    print_log('vc_sort_filter', $current->to_string . ' is filtered out');
  };

  $self->{current} = undef;
  return;
};


# Get current document
sub current {
  $_[0]->{current};
};


# Skip to the relevant document
sub skip_doc {
  my ($self, $doc_id) = @_;

  my $query = $self->{query};

  # Skip the document
  if ($query->skip_doc($doc_id)) {

    # Return the document id, if it matches
    return $doc_id if $query->_check;

    # Get the next matching element
    if ($self->next) {

      # return the document id
      return $self->{current}->doc_id;
    };
  };

  # Fail
  return;
};


1;
