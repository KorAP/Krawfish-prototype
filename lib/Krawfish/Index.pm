package Krawfish::Index;
use Krawfish::Index::Dictionary;
use Krawfish::Index::Subtokens;
use Krawfish::Index::PrimaryData;
use Krawfish::Index::Fields;
use Krawfish::Cache;
use Krawfish::Log;
use strict;
use warnings;
use Scalar::Util qw!blessed!;
use Mojo::JSON qw/encode_json decode_json/;
use Mojo::File;

# TODO: This should be a base class for K::I::Static and K::I::Dynamic



# TODO: Add LiveDocs-PostingsList, that supports deletion
#
# TODO: Support multiple tokenized texts for parallel corpora
#
# TODO: Create Importer class
#
# TODO: Support Main Index and Auxiliary Indices with merging
# https://www.youtube.com/watch?v=98E1h_u4xGk
#
# TODO: Maybe logarithmic merge
# https://www.youtube.com/watch?v=VNjf2dxWH2Y&spfreload=5

# TODO: Maybe 65.535 documents are enough per segment ...

# TODO: Build a forward index
# TODO: With a forward index, the subtokens offsets will no longer
#   point to character positions in the primary text but to
#   subtoken positions in the forward index!

# TODO:
#   Currently ranking is not collation based. It should be possible
#   to define a collation per field and
#   use one collation for prefix and suffix sorting.
#   It may be beneficial to make a different sorting possible (though it's
#   probably acceptable to make it slow)
#   Use http://userguide.icu-project.org/collation

# TODO:
#   Reranking a field is not necessary, if the field value is already given.
#   In that case, look up the dictionary if the value is already given,
#   take the example doc of that field value and add the rank of that
#   doc for the new doc.
#   If the field is not yet given, take the next or previous value in dictionary
#   order and use the rank to rerank the field (see K::I::Dictionary).
#   BUT: This only works if the field has the same collation as the
#   dictionary!

# TODO:
#   field names should have term_ids, so should foundries and layers, but
#   probably not field values and annotation values.
#   terms may have term_ids and subterms should have subterm_ids


use constant DEBUG => 0;


sub new {
  my $class = shift;
  my $file = shift;
  my $self = bless {
    file => $file
  }, $class;

  print_log('index', 'Instantiate new index') if DEBUG;

  # Load dictionary
  $self->{dict} = Krawfish::Index::Dictionary->new(
    $self->{file}
  );

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

  # Create a list of docid -> uuid mappers
  # This may be problematic as uuids may need to be uint64,
  # this can grow for a segment with 65.000 docs up to ~ 500kb
  # Or ~ 7MB for 1,000,000 documents
  # But this means it's possible to store
  # 18.446.744.073.709.551.615 documents in the index
  $self->{identifier} = [];

  # Collect fields to sort
  $self->{sortable} = {};

  # Collect values to sum
  $self->{summable} = {};

  # Add cache
  $self->{cache} = Krawfish::Cache->new;

  # TODO: Get last_doc_id from index file
  $self->{last_doc} = 0;

  return $self;
};


# Get last document index
sub last_doc {
  $_[0]->{last_doc};
};


# Alias for last doc
sub max_rank {
  $_[0]->{last_doc};
};


# Get term dictionary
sub dict {
  $_[0]->{dict};
};


# Get info
sub info {
  $_[0]->{info};
};


# Get subtokens
sub subtokens {
  $_[0]->{subtokens};
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
  $_[0]->{field_values};
};


# Add document to the index
# TODO: Expect a KoralQuery document
# TODO: This should be specific to Krawfish::Index::Dynamic;
sub add {
  my $self = shift;
  my $doc = shift;
  unless (ref $doc) {
    $doc = decode_json(Mojo::File->new($doc)->slurp);
  };

  # Get new doc_id
  my $doc_id = $self->{last_doc}++;

  # Get document
  $doc = $doc->{document};

  # Store primary data
  if ($doc->{primaryData}) {

    # TODO: This may, in the future, contain the forward index instead
    $self->primary->store($doc_id, $doc->{primaryData});

    print_log('index', 'Store primary data "' . $doc->{primaryData} . '"') if DEBUG;
  };

  my $pos = 0;

  # Store identifier for mappings
  # But what is the purpose of the identifier?
  # Isn't it okay to be slow here ... ?
  if ($doc->{id}) {
    $self->{identifier}->[$doc_id] = $doc->{id};
  };

  my $dict = $self->{dict};

  # Add metadata fields
  my $fields = $self->fields;
  foreach my $field (@{$doc->{fields}}) {

    # TODO:
    #   Also store 'id' as a field value

    # Add to document field (retrieval)
    $fields->store($doc_id, $field->{key}, $field->{value});

    # Prepare for summarization
    # if ($field->{type} eq 'type:integer') {
    # };

    # Prepare field for sorting
    if ($field->{sortable}) {

      # Which entries need to be sorted?
      $self->{sortable}->{$field->{key}}++;
    };

    # Prepare field for summing
    # if ($field->{summable}) {
    #
    #   # Which entries need to be summable
    #   $self->{summable}->{$field->{key}}++;
    # };

    # Add to postings lists (search)
    my $term = $field->{key} . ':' . $field->{value};
    my $post_list = $dict->add_term('+' . $term);
    $post_list->append($doc_id);
  };

  my $subtokens = $self->subtokens;

  # The primary text is necessary for the subtoken index as well as
  # for the forward index
  my $primary = $doc->{primaryData};

  # Store subtokens
  if ($doc->{subtokens}) {

    print_log('index', 'Store subtokens') if DEBUG;

    # Store all subtoken offsets
    foreach my $seg (@{$doc->{subtokens}}) {

      # Get start and end of the subtoken
      my ($start, $end) = @{$seg->{offsets}};

      if (DEBUG) {
        print_log(
          'index',
          'Store subtoken: ' . $doc_id . ':' . $pos . '=' . join('-', $start, $end)
        );
      };

      # Get the term surface from the primary text
      # TODO: Ensure that the offsets are valid!
      my $term = substr($primary, $start, $end - $start);

      # TODO: There may be a prefix necessary for surface forms
      # TODO: This may in fact be not necessary at all -
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
        my $post_list = $dict->add_term($_);
        $post_list->append($doc_id, @subtokens);
      };
    }

    # Add span term to dictionary
    elsif ($item->{'@type'} eq 'koral:span') {

      # Create key string
      my $key = '<>' . _term($item->{wrap});

      my $post_list = $dict->add_term($key);

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


# Apply (aka search) the index
sub apply {
  my $self = shift;
  my $koral = shift;

  # Necessary for filtering
  my $corpus = $koral->corpus->prepare_for($self) or return;

  # Add VC to query as a constraint
  my $query = $koral->query->prepare_for($self, $corpus) or return;

  # Get meta information
  my $meta = $koral->meta->prepare_for($self) or return;

  my $cb = shift;
  my @result = ();

  # No callback - push to array
  unless ($cb) {
    while ($query->next) {
      push @result, $query->current;
    };
    return @result;
  };

  # Push callback
  while ($query->next) {
    $cb->($query->current);
  };

};



1;


__END__



# Search using meta data
# Can also be used to collect with a callback
#
sub search {
  my ($self, $koral, $cb) = @_;

  my $query  = $koral->query;
  my $corpus = $koral->corpus;
  my $meta   = $koral->meta;

  # Initiate result object
  my $result = $koral->result;

  # Get filtered search object
  my $search = $query->filter_by($corpus)->plan_for($self);

  # Augment with facets
  # Will add to result info
  if ($meta->facets) {
    $search = $meta->facets($search);
  };

  # Augment with counting
  # Will add to result info
  if ($meta->count) {
    $search = $meta->count($search);
  };

  # Augment with sorting
  if ($meta->sorted_by) {
    $search = $meta->sorted_by($search);
  };

  # Augment with limitations
  if ($meta->limit) {
    $search = $meta->limit($search);
  };

  # Augment with field collector
  # Will modify current match
  $search = $meta->fields($search);

  # Augment with id creator
  # Will modify current match
  $search = $meta->id_create($search);

  # Augment with snmippet creator
  # Will modify current match
  $search = $meta->snippets($search);

  # Iterate over all matches
  while ($search->next) {

    # Based on the information, this will populate the match
    $result->add_match($search->current_match);
  };

  return $koral;
};

sub get_fields {
  my ($self, $doc_id, $fields) = @_;
  ...
};

# This returns the posting's start and end position
# when embedded in a span, e.g. <base/s=s>
sub get_context_by_query {
  my ($self, $posting, $query) = @_
};

sub get_annotations {
  my ($self, $posting, $terms) = @_;

  my %anno = ();

  my $dict = $self->dict;
  foreach my $term ($dict->terms($terms)) {
    my $term_list = $dict->get($term);

    # Skip to the correct document and the first position
    next unless $term_list->next($posting->doc_id, $posting->start);

    # Init annotation
    my $anno = ($anno{$term} //= []);

    # Iterate over all annotations
    while ($term_list->current->end <= $posting->end) {

      # Remember the annotations
      push @$anno, $term_list->current->clone;

      $term_list->next or next;
    }

    # Close (and forget) termlist
    $term_list->close;
  };

  return \%anno;
};





sub items_per_page;

sub start_page;

sub apply {
  my $self = shift;
  my $query = $self->plan;
  my $cb = shift;
  my @result = ();

  # No callback - push to array
  unless ($cb) {
    while ($query->next) {
      push @result, $query->current;
    };
    return @result;
  };

  # Push callback
  while ($query->next) {
    $cb->($query->current);
  };
};
