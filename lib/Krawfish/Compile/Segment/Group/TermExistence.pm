package Krawfish::Compile::Segment::Group::TermExistence;
use parent 'Krawfish::Compile';
use strict;
use warnings;

# The query works similar to Or-query, but only accepts term ids.

sub new {
  my $class = shift;
  bless {
    term_id   => shift,  # Term Query
    term_ids  => shift,  # Optional TermExistence-Query
    filter    => undef,
    existence => []
  }, $class;
};

sub _init {
  ...
};


# TODO:
#   Think about when next() is called, as it needs to be called on term_ids as well ...
#   Mabe this should be done in _init as a while query somehow.
sub next {
  my $self = shift;

  # Get the current document in the VC
  my $filter = $self->{filter};
  my $doc_id = $filter->doc_id;

  # The next document to look for in the VC
  my $next_doc_id;


  # Check the single term_id for existence

  # The simple term does not exist
  my $term = $self->{term_id};
  if (!$term) {
    # Do nothing
  }

  # Should never happen
  elsif (!$term->current) {
    $self->{term_id} = undef;
  }

  # Term exists and can be checked
  else {

    # Is the VC document beyond the current document id
    if ($doc_id > $term->doc_id) {

      # Move the term document to the VC document
      $term->skip_doc($doc_id);
    };

    # Are both terms in the same document?
    if ($term->doc_id == $doc_id) {

      # Add this term to existence
      $self->exists($term->term_id);

      # Close posting
      $term->close;

      # Do not check any further
      $self->{term_id} = undef;
    }

    # Current term document is beyond current VC doc
    else {
      $next_doc_id = $term->doc_id;
    };
  };


  # Check the complex term_ids for existence

  my $terms = $self->{term_ids};

  if (!$terms) {
    # Do nothing
  }

  # Should never happen
  elsif (!$terms->current) {
    $self->{term_ids} = undef;
  }

  else {

    # When there is a complex query, move on
    if ($doc_id > $terms->doc_id) {
      $terms->skip_doc($doc_id);
    };

    # There are no further matches
    unless ($terms->current) {

      # Merge existence values
      $self->exists($terms->existence);
      $terms->close;
      $self->{term_ids} = undef;
    }

    # Current terms are beyond current VC doc
    else {

      # Remember the next relevant document id
      if (!$next_doc_id || $next_doc_id > $term->doc_id) {
        $next_doc_id = $term->doc_id;
      };
    };
  };

  # There is a next document id defined - move on
  if (defined $next_doc_id) {

    # Move the VC stream to the next relevant position
    if ($filter->skip_doc($next_doc_id)) {

      # It's fine
      return 1;
    };
  };

  return 0;
};


# Add term ids to existence list
sub exists {
  my ($self, $term_id) = @_;

  if (ref $term_id) {
    push @{$terms->existence}, @$term_id;
  }
  else {
    push @{$terms->existence}, $term_id;
  };
};


# Return list of existing term ids
sub existence {
  return $self->{existence}
};


sub filter_by {
  ...
    # It is relevant to filter The query - but one filter may be enough
};


1;
