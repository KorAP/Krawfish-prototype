package Krawfish::Index::Segment;
use Krawfish::Index::Subtokens;
use Krawfish::Index::PrimaryData;  # Maybe irrelevant
use Krawfish::Index::Fields;
use Krawfish::Index::PostingsLive;
use Krawfish::Index::PostingsList;
use Krawfish::Index::Forward;
use Krawfish::Cache;
use Krawfish::Log;
use Scalar::Util qw!blessed!;
use strict;
use warnings;

# Return segment information for term ids
# This is the base for dynamic and
# static segment stores.

#
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


use constant DEBUG => 0;

sub new {
  my $class = shift;
  my $file = shift;
  my $self = bless {
    file => $file
  }, $class;

  print_log('seg', 'Instantiate new segment') if DEBUG;

  # Load offsets
  $self->{subtokens} = Krawfish::Index::Subtokens->new(
    $self->{file}
  );

  # Load primary
  $self->{primary} = Krawfish::Index::PrimaryData->new(
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

  # Create a list of docid -> uuid mappers
  # This may be problematic as uuids may need to be uint64,
  # this can grow for a segment with 65.000 docs up to ~ 500kb
  # Or ~ 7MB for 1,000,000 documents
  # But this means it's possible to store
  # 18.446.744.073.709.551.615 documents in the index
  # $self->{identifier} = [];

  # Collect fields to sort
  $self->{sortable} = {};

  # Collect values to sum
  $self->{summable} = {};

  # Add cache
  $self->{cache} = Krawfish::Cache->new;

  # Add forward index
  $self->{forward} = Krawfish::Index::Forward->new;

  return $self;
};


sub add_sortable {
  my ($self, $field) = @_;
  $self->{sortable}->{$field}++;
};


# Get the last document index
sub last_doc {
  $_[0]->{live}->next_doc_id - 1;
};


# Alias for last doc
sub max_rank {
  $_[0]->{live}->next_doc_id - 1;
};


# Get subtokens
sub subtokens {
  $_[0]->{subtokens};
};


# Get live documents
sub live {
  $_[0]->{live};
};


# Get primary
sub primary {
  $_[0]->{primary};
};


# Get fields
sub fields {
  $_[0]->{fields};
};


# Get field values for addition
sub field_values {
  warn 'DEPRECATED';
  $_[0]->{field_values};
};


# Return a postings list
# based on a term_id
sub postings {
  my ($self, $term_id) = @_;

  $self->{$term_id} //= Krawfish::Index::PostingsList->new(
    'unknown', 'unknown', $term_id
  );

  return $self->{$term_id};
};


sub forward {
  $_[0]->{forward};
};


# This will make add() in Krawfish::Index obsolete
sub add {
  my ($self, $doc) = @_;

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

  # TODO:
  #   Deal with sortables!

  # $self->invert->add()

  # Create term index for fields
  my $fields = $doc->fields;
  foreach (@$fields) {
    if (DEBUG) {
      print_log('seg', 'Added field #' . $_->term_id . ' for doc_id=' . $doc_id);
    };
    $self->postings($_->term_id)->append($doc_id);
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


1;
