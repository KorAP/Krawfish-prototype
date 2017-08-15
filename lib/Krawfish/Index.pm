package Krawfish::Index;
use Krawfish::Log;
use Krawfish::Index::Dictionary;
use Krawfish::Index::Segment;
use Mojo::JSON qw/encode_json decode_json/;
use Mojo::File;
use strict;
use warnings;

use constant DEBUG => 0;

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
#   This should be a base class for K::I::Static and K::I::Dynamic
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

  $self->{segments} = [];

  $self->{dyn_segment} = Krawfish::Index::Segment->new(
    $self->{file}
  );

  return $self;
};


# Get the segments array
sub segments {
  $_[0]->{segments}
};


# Get the dynamic segment
sub segment {
  $_[0]->{dyn_segment};
};


# Get the dictionary
sub dict {
  $_[0]->{dict};
};


# Add document to the index
# TODO: Expect a KoralQuery document
# TODO: This should be specific to Krawfish::Index::Dynamic;
# TODO: Support update as a insert_after_delete
# TODO: Updated caches!
sub add {
  my ($self, $doc, $replicant_id) = @_;

  # TODO:
  #   The document should first be converted in inverted index form
  #   using a hash with
  #
  #   +field => title,
  #   *term => [postings*]
  #
  #   Then, when the document is added to certain nodes,
  #   the keys will be translated to term_ids and the document
  #   can be added with all freq_in_doc information
  unless (ref $doc) {
    $doc = decode_json(Mojo::File->new($doc)->slurp);
  };

  # Get the dynamic segment to add the document
  my $seg = $self->segment;

  # Get new doc_id for the segment
  my $doc_id = $seg->live->incr;

  # Get document
  $doc = $doc->{document};

  # Store primary data
  if ($doc->{primaryData}) {

    # TODO: This may, in the future, contain the forward index instead
    $seg->primary->store($doc_id, $doc->{primaryData});

    print_log('index', 'Store primary data "' . $doc->{primaryData} . '"') if DEBUG;
  };

  my $pos = 0;

  # Store identifier for mappings
  # But what is the purpose of the identifier?
  # Isn't it okay to be slow here ... ?
  # if ($doc->{id}) {
  #   $seg->{identifier}->[$doc_id] = $doc->{id};
  # };

  my $dict = $self->{dict};

  # Add metadata fields
  my $fields = $seg->fields;
  foreach my $field (@{$doc->{fields}}) {

    # TODO:
    #   Presort fields based on their field_key_id!
    #   In that way it's faster to retrieve presorted fields
    #   for enrichment!

    # Prepare for summarization
    # if ($field->{type} eq 'type:integer') {
    # };

    # Prepare field for sorting
    if ($field->{sortable}) {

      # Which entries need to be sorted?
      $seg->add_sortable($field->{key});
    };

    # Prepare field for summing
    # if ($field->{summable}) {
    #
    #   # Which entries need to be summable
    #   $self->{summable}->{$field->{key}}++;
    # };

    # Add to postings lists (search)
    my $term = $field->{key} . ':' . $field->{value};

    # Add the term to the dictionary
    my $term_id = $dict->add_term('+' . $term);

    # Add the field key to the dictionary
    my $field_id = $dict->add_term('!' . $field->{key});

    # Get the posting list for the term
    my $post_list = $seg->postings($term_id);

    # Append the document to the posting list
    $post_list->append($doc_id);

    # TODO:
    #   Also store 'id' as a field value

    # Add to document field (for retrieval)
    # This is stored as field_id and term_id
    $fields->store($doc_id, $field_id, $term_id);
  };


  # Set replication fields
  if (0) {
    my $term;
    if ($replicant_id) {
      $term = '2:' . $replicant_id;
    }
    else {
      $term = '1:1';
    };


    # TODO:
    #   The term_id for 1:1 should be known!

    # Add term to dictionary
    my $term_id = $dict->add_term('__' . $term);

    # Add posting to list
    my $post_list = $seg->postings($term_id);
    $post_list->append($doc_id);
  };


  # Get subtoken list
  my $subtokens = $seg->subtokens;

  # The primary text is necessary for the subtoken index as well as
  # for the forward index
  my $primary = $doc->{primaryData};

  # Store subtokens
  if ($doc->{subtokens}) {

    print_log('index', 'Store subtokens') if DEBUG;

    # Store all subtoken offsets
    foreach my $subtoken (@{$doc->{subtokens}}) {

      # Get start and end of the subtoken
      my ($start, $end) = @{$subtoken->{offsets}};

      if (DEBUG) {
        print_log(
          'index',
          'Store subtoken: ' . $doc_id . ':' . $pos . '=' . join('-', $start, $end)
        );
      };

      # Get the term surface from the primary text
      # TODO:
      #   Ensure that the offsets are valid!
      my $term = substr($primary, $start, $end - $start);

      # TODO:
      #   There may be a prefix necessary for surface forms ('*')

      # TODO:
      #   This may in fact be not necessary at all -
      #   The subtokens may have their own IDs
      #   And the terms do not need to be stored in the dictionary for retrieval ...

      # Add as a subterm
      my $subterm_id = $dict->add_subterm($term);

      # TODO:
      #   Check somehow, if the term is new. If so, then {
      #     TODO: Store case insensitive term
      #       $dict->add_subterm_casefolded(fold_case($term), $subterm_id);
      #       $dict->add_subterm_without_diacritics(remove_diacritics($term), $subterm_id);
      #   }

      print_log('index', 'Surface form has subterm_id ' . $subterm_id) if DEBUG;

      # Store information to subtoken
      $subtokens->store(
        $doc_id,
        $pos++,
        $start,
        $end,
        $subterm_id,
        $term # Probably not necessary!
      );
    };
  };

  # Get all tokens
  $pos = 0;
  my $end;
  foreach my $item (@{$doc->{annotations}}) {

    # Add token term to term dictionary
    if ($item->{'@type'} eq 'koral:token') {

      unless ($item->{wrap}) {
        warn 'No wrap defined in KoralQuery';
        next;
      };

      # Create key string
      my $wrap = $item->{wrap};
      my @keys;

      # Token wraps a koral:termGroup
      if ($wrap->{'@type'} && $wrap->{'@type'} eq 'koral:termGroup')  {
        foreach (@{$wrap->{operands}}) {
          push @keys, _term($_);
        };
      }

      # Token wraps a single koral:term
      else {
        push @keys, _term($wrap);
      };

      # Append posting to postings list
      my @subtokens = _subtokens($item);

      # No subtokens defined
      unless (scalar @subtokens) {
        push @subtokens, $pos;

        # Store offsets
        if ($item->{offsets}) {
          $subtokens->store($doc_id, $pos, @{$item->{offsets}});
        };
        $pos++;
      };

      # Add token terms
      foreach (@keys) {
        my $term_id = $dict->add_term($_);
        my $post_list = $seg->postings($term_id);
        $post_list->append($doc_id, @subtokens);
      };
    }

    # Add span term to dictionary
    elsif ($item->{'@type'} eq 'koral:span') {

      # Create key string
      my $key = '<>' . _term($item->{wrap});

      my $term_id = $dict->add_term($key);
      my $post_list = $seg->postings($term_id);

      # Append posting to posting list
      $post_list->append(
        $doc_id,
        $item->{subtokens}->[0],
        # The end is AFTER the second subtoken
        $item->{subtokens}->[-1] + 1
      );
    };
  };

  return $doc_id;
};


# TODO: Use from_koral()->term
# Potentially with a prefix
sub _term {
  my $item = shift;

  my $key = '';
  # Create term for term dictionary
  if ($item->{foundry}) {
    $key .= $item->{foundry};
    if ($item->{layer}) {
      $key .= '/' . $item->{layer};
    }
    $key .= '=';
  };
  return $key . ($item->{key} // '');
}


# Return subtoken list or nothing
sub _subtokens {
  my $item = shift;
  my @posting;

  if ($item->{subtokens}) {

    # Remove!
    push @posting, $item->{subtokens}->[0];

    if ($item->{subtokens}->[1]) {
      # The end is AFTER the second subtoken
      push @posting, $item->{subtokens}->[1] + 1;
    };

    return @posting;
  };

  return;
};

1;

