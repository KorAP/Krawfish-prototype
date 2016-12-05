package Krawfish::Index;
use Krawfish::Index::Dictionary;
use Krawfish::Index::Offsets;
use Krawfish::Index::PrimaryData;
use Krawfish::Index::Fields;
use strict;
use warnings;
use Scalar::Util qw!blessed!;
use Mojo::JSON qw/encode_json decode_json/;
use Mojo::Util qw/slurp/;

# TODO: Add LiveDocs-PostingsList, that supports deletion
#
# TODO: Create Importer class
#
# TODO: Support Main Index and Auxiliary Indices with merging
# https://www.youtube.com/watch?v=98E1h_u4xGk
#
# TODO: Maybe logarithmic merge
# https://www.youtube.com/watch?v=VNjf2dxWH2Y&spfreload=5

sub new {
  my $class = shift;
  my $file = shift;
  my $self = bless {
    file => $file
  }, $class;

  # Load dictionary
  $self->{dict} = Krawfish::Index::Dictionary->new(
    $self->{file}
  );

  # Load offsets
  $self->{offsets} = Krawfish::Index::Offsets->new(
    $self->{file}
  );

  # Load primary
  $self->{primary} = Krawfish::Index::PrimaryData->new(
    $self->{file}
  );

  # Load primary
  $self->{fields} = Krawfish::Index::Fields->new(
    $self->{file}
  );

  # TODO: Get last_doc_id from index file
  $self->{last_doc} = 0;

  return $self;
};


# Get last document index
sub last_doc {
  $_[0]->{last_doc};
};


# Get term dictionary
sub dict {
  $_[0]->{dict};
};

sub info {
  $_[0]->{info};
};

# Get offsets
sub offsets {
  $_[0]->{offsets};
};


# Get primary
sub primary {
  $_[0]->{primary};
};

# Get fields
sub fields {
  $_[0]->{fields};
};


# Add document to the index
# TODO: Expect a KoralQuery document
sub add {
  my $self = shift;
  my $doc = shift;
  unless (ref $doc) {
    $doc = decode_json slurp $doc;
  };

  # Get new doc_id
  my $doc_id = $self->{last_doc}++;

  # Get document
  $doc = $doc->{document};

  # Store primary data
  $self->primary->store($doc_id, $doc->{primaryData});

  my $offsets = $self->offsets;

  my $pos = 0;
  my @segments = ();

  # Store segments
  if ($doc->{segments}) {

    # Store all segment offsets
    foreach my $seg (@{$doc->{segments}}) {
      $offsets->store($doc_id, $pos++, @{$seg->{offsets}});
    };
  };

  my $dict = $self->{dict};

  # Add metadata fields
  my $fields = $self->fields;
  foreach my $field (@{$doc->{fields}}) {

    # Add to document field (retrieval)
    $fields->store($doc_id, $field->{key}, $field->{value});

    # Add to postings lists (search)
    my $term = $field->{key} . ':' . $field->{value};
    my $post_list = $dict->add('+' . $term);
    $post_list->append($doc_id);
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
      my @segments = _segments($item);

      # No segments defined
      unless (scalar @segments) {
        push @segments, $pos;

        # Store offsets
        if ($item->{offsets}) {
          $offsets->store($doc_id, $pos, @{$item->{offsets}});
        };
        $pos++;
      };

      foreach (@keys) {
        my $post_list = $dict->add($_);
        $post_list->append($doc_id, @segments);
      };
    }

    # Add span term to dictionary
    elsif ($item->{'@type'} eq 'koral:span') {

      # Create key string
      my $key = '<>' . _term($item->{wrap});

      my $post_list = $dict->add($key);

      # Append posting to posting list
      $post_list->append(
        $doc_id,
        $item->{segments}->[0],
        # The end is AFTER the second segment
        $item->{segments}->[-1] + 1
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


# Return segment list or nothing
sub _segments {
  my $item = shift;
  my @posting;

  if ($item->{segments}) {

    # Remove!
    push @posting, $item->{segments}->[0];

    if ($item->{segments}->[1]) {
      # The end is AFTER the second segment
      push @posting, $item->{segments}->[1] + 1;
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
sub search {
  my ($self, $koral, $cb) = @_;

  my $query  = $koral->query;
  my $corpus = $koral->corpus;
  my $meta   = $koral->meta;

  # Results
  my $result = $koral->result;

  my $search = $query->filter_by($corpus)->plan_for($self);

  # Augment with facets
  if ($meta->facets) {
    $search = $meta->facets($search);
  };

  # Augment with sorting
  if ($meta->sort) {
    $search = $meta->sort($search);
  };

  my $count = 0;
  while ($search->next) {
    my $posting = $search->current;

    # Based on the information, this will populate the match
    $result->add_match($posting, $index);

    last if ++$count > $meta->count;
  };

  # Total result count may already be available after sorting
  # Otherwise count
  if (!$meta->total_results && !$meta->cutoff) {
    $count++ while $search->next;
    $meta->total_results($count);
  };

  return $koral;
};

sub get_fields {
  my ($self, $doc_id, $fields) = @_;
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
