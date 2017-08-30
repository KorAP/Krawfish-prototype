package Krawfish::Index;
use Krawfish::Log;
use Krawfish::Index::Dictionary;
use Krawfish::Index::Segment;
use Mojo::JSON qw/encode_json decode_json/;
use Mojo::File;
use strict;
use warnings;

use constant DEBUG => 1;

# TODO:
#   May need to be renamed to Krawfish::Node


# This is the central object for index handling on node level.
# A new document will be added by adding the following information:
# - To the dynamic DICTIONARY
#   - subterms
#   - terms
#   - fields
#   - field keys
#   - foundries                    (TODO)
#   - foundry/layer                (TODO)
#   - foundry/layer:annotations
#   - regarding ranks
#     - subterms                   (TODO)
#       (2 ranks for forward and reverse sorting)
# - To the dynamic RANGE DICTIONARY
#   - fields (with integer data)
# - To the dynamic SEGMENT
#   - regarding postings lists
#     - terms
#     - annotations
#     - fields
#     - live document
#   - regarding document lists
#     - fields
#     - field keys
#     - numerical field values     (TODO)
#   - regarding forward index      (TODO)
#     - subterms
#     - annotations
#     - gap characters
#   - regarding ranks
#     - fields
#       (2 ranks for multivalued fields)
#   - regarding subtoken lists
#     - subterms
#   - regarding token spans        (TODO)
#     - tokens
#       (1 per foundry)
#
# The document can be added either as a primary document or as a replicated
# document with a certain node_id.
# Dynamic Segments can be merged with static indices once in a while.
# Dynamic dictionaries can be merged with static indices once in a while.

# TODO:
#   Create Importer class
#
# TODO:
#   Support multiple tokenized texts for parallel corpora
#
# TODO:
#   Support Main Index and Auxiliary Indices with merging
#   https://www.youtube.com/watch?v=98E1h_u4xGk
#
# TODO:
#   Maybe logarithmic merge
#   https://www.youtube.com/watch?v=VNjf2dxWH2Y&spfreload=5

# TODO:
#   Maybe 65.535 documents are enough per segment ...

# TODO:
#   Commits need to be logged and per commit, information
#   regarding newly added documents need to be accessible.

# TODO:
#   Currently ranking is not collation based. It should be possible
#   to define a collation per field and
#   use one collation for prefix and suffix sorting.
#   It may be beneficial to make a different sorting possible (though it's
#   probably acceptable to make it slow)
#   Use http://userguide.icu-project.org/collation

# Construct a new index object
sub new {
  my $class = shift;
  my $file = shift;
  my $self = bless {
    file => $file
  }, $class;

  $self->{dict} = Krawfish::Index::Dictionary->new(
    $self->{file}
  );

  # The first segment in the list of segments is always the dynamic one
  $self->{segments} = [
    Krawfish::Index::Segment->new(
      $self->{file}
    )
  ];

  return $self;
};


# Get the segments array
sub segments {
  $_[0]->{segments}
};


# Get the dynamic segment
sub segment {
  $_[0]->{segments}->[0];
};


# Get the dictionary
sub dict {
  $_[0]->{dict};
};


# Introduce a new field, possibly for sorting
sub introduce_field {
  my ($self, $field_term, $locale) = @_;

  my $dict = $self->dict;

  # Add field
  if (my $term_id = $dict->add_field($field_term, $locale)) {

    # Field is meant to be sortable
    if ($locale eq 'NUM') {

      if (DEBUG) {
        print_log('index', 'Introduce field ' . $field_term . ' as sortable');
      }

      # Propagate the field to all segments
      foreach (@{$self->segments}) {

        # Introduce ranking file on all segments
        $_->field_ranks->introduce_rank($term_id, 'NUM');
      };
    }
    else {
      # Get collation object
      # TODO:
      #   Better only forward the locale and get the collation
      #   object when necessary
      my $coll = $self->dict->collations->get($locale);

      # Propagate the field to all segments
      foreach (@{$self->segments}) {

        # Introduce ranking file on all segments
        $_->field_ranks->introduce_rank($term_id, $coll);
      };
    };

    # Field is added to the dictionary
    return 1;
  };

  # Field can't be added, because the collations are
  # incompatible

  # Get term id (again)
  my $term_id = $dict->term_id_by_term('!' . $field_term);

  # Get the collation that is currently used
  my $stored_locale = $dict->collation($term_id);

  # The field already consists and it differs regarding the
  # collation - no upgrade possible
  return;

  # TODO:
  #  1. No introduced collation
  #     Remove all rank files from all segments
  #  2. Incompatible collation
  #     Iterate over all fields for all documents and
  #     create sorted lists for the field.
  #     This may take quite a while.
};


# Commit all pending data
sub commit {
  my $self = shift;

  # Commit changes to the dictionary
  # my $changes = $self->dict->commit;

  # The commit returns the IDs of newly added documents
  my $changed = $self->segment->commit;

  # Deletes are not part of the commit,
  # although they are reported as commits

  # TODO:
  #   Commits need to be logged and per commit, information
  #   regarding newly added documents need to be accessible
  #   on the cluster level

  return 1;
};


1;

