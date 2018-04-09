package Krawfish::Index::Segment;
use Krawfish::Index::Fields;
use Krawfish::Index::Fields::Ranks;
use Krawfish::Index::PostingsLive;
use Krawfish::Index::PostingsList;
use Krawfish::Index::Forward;
use Krawfish::Cache;
use Krawfish::Log;
use Scalar::Util qw!blessed!;
use strict;
use warnings;

# Return segment information.
# This is the base for dynamic and
# static segment stores.

# TERMS: The dictionary will have one value lists with data,
#        accessible by their term_id position in the list:
#
#  ([leaf-backref][freq][postinglistpos])*
#
#  However - it may be useful to have the postinglistpos
#  separated per segment, so it's
#  seg1:[postinglistpos1][postinglistpos2][0][postinglistpos4]
#  seg1:[postinglistpos1][postinglistpos2][postinglistpos3][0]
#  ...
#
# SUBTERMS: The dictionary will have one list with data,
#           accessible by their sub_term_id position in the list:
#  ([leaf-backref][prefix-rank][suffix-rank])*

# TODO:
#   Store token information per foundry/layer tokens

# TODO:
#   Which fields are sortable can be retrieved from the dictionary.

use constant DEBUG => 0;


# Constructor
sub new {
  my $class = shift;
  my $file = shift;
  my $self = bless {
    file => $file
  }, $class;

  print_log('seg', 'Instantiate new segment') if DEBUG;

  # Add forward index
  $self->{forward} = Krawfish::Index::Forward->new(
    $self->{file}
  );

  # Load fields
  $self->{fields} = Krawfish::Index::Fields->new(
    $self->{file}
  );

  # Load live document pointer
  $self->{live} = Krawfish::Index::PostingsLive->new(
    $self->{file}
  );

  $self->{field_ranks} = Krawfish::Index::Fields::Ranks->new(
    $self->{file}
  );

  # Create a list of docid -> uuid mappers
  # This may be problematic as uuids may need to be uint64,
  # this can grow for a segment with 65.000 docs up to ~ 500kb
  # Or ~ 7MB for 1,000,000 documents
  # But this means it's possible to store
  # 18.446.744.073.709.551.615 documents in the index
  # $self->{identifier} = [];

  # Remember fields to sort
  # $self->{sortable} = {};

  # Add cache
  $self->{cache} = Krawfish::Cache->new;

  return $self;
};


# Get the last document index
sub last_doc {
  $_[0]->{live}->next_doc_id - 1;
};


# Get the maximum possible rank
sub max_rank {
  $_[0]->{live}->next_doc_id;
};


# Get subtokens
sub subtokens {
  $_[0]->{subtokens};
};


# Get live documents
sub live {
  $_[0]->{live};
};


# Get fields index
sub fields {
  $_[0]->{fields};
};


# Get forward index
sub forward {
  $_[0]->{forward};
};


# Get field ranks
sub field_ranks {
  $_[0]->{field_ranks};
};


# Return a postings list based on a term_id
sub postings {
  my ($self, $term_id) = @_;

  # TODO:
  #   There may already be a prepared pool of postingslist
  #   based on the numerically sorted term ids

  $self->{$term_id} //= Krawfish::Index::PostingsList->new(
     $self->{file}, $term_id
  );

  return $self->{$term_id};
};



# Add a prepared document to the index
sub add {
  my ($self, $doc) = @_;

  # TODO:
  #   This may use a prepared pool of PostingsLists
  #   that are lifted before - for term_ids in numerical order

  # TODO:
  # Alternatively get this from the forward index
  # Get new doc_id for the segment
  my $doc_id = $self->live->incr;

  # TODO:
  #   The document should already have a field with __1:1 and id!
  my $doc_id_2 = $self->fields->add($doc);

  # TODO:
  #   Index forward index
  #   Alternatively, this could be done in the same method here!
  my $doc_id_3 = $self->forward->add($doc);

  # TODO:
  #   Rank fields!
  # $self->field_ranks();

  # $self->invert->add()

  # Create term index for fields
  my $fields = $doc->fields;
  my $ranks  = $self->field_ranks;
  foreach (@$fields) {
    next if $_->type eq 'store';
    if (DEBUG) {
      print_log('seg', 'Added field #' . $_->term_id . ' for doc_id=' . $doc_id);
    };
    $self->postings($_->term_id)->append($doc_id);

    # The field is sortable
    if ($_->sortable) {

      # Add field value to ranking
      my $ranked_by = $ranks->by($_->key_id);

      if (DEBUG) {
        print_log('seg', 'Field ' . $_->key . ' is sortable');
      };

      $ranked_by->add($_->value, $doc_id) if $ranked_by;
    }

    elsif (DEBUG) {
      print_log('seg', 'Field ' . $_->key . ' is NOT sortable');
    };
  };


  # TODO:
  #   This should probably collect all [term_id => data] in advanced,
  #   so skiplist info, freq_in_doc etc. can be adjusted in advance
  my $stream = $doc->stream;
  for (my $start = 0; $start < $stream->length; $start++) {
    my $subtoken = $stream->subtoken($start);

    # This is the last token - only existing for preceeding bytes
    next unless $subtoken->term_id;

    # Add subtoken to postingslist
    $self->postings($subtoken->term_id)->append($doc_id, $start, $start + 1);

    if (DEBUG) {
      print_log('seg', 'Added subterm #' . $subtoken->term_id . ' for doc_id=' . $doc_id);
    };

    # Add all annotations
    foreach (@{$subtoken->annotations}) {
      $self->postings($_->term_id)->append($doc_id, $start, @{$_->data});

      if (DEBUG) {
        print_log('seg', 'Added anno term #' . $_->term_id . ' for doc_id=' . $doc_id);
      };
    };
  };

  return $doc_id;
};


# Commiting is only relevant for the dynamic segment,
# TODO:
#   Per default merge with a static segment
sub commit {
  my $self = shift;

  # Commit ranks
  $self->field_ranks->commit;

  # $self->fields->commit;

  # Return the list of newly added doc ids
  # my @docs = $self->forward->commit;

  # return @docs;
  return 1;
};


1;
