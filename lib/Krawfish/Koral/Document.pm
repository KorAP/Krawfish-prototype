package Krawfish::Koral::Document;
use Krawfish::Koral::Document::Stream;
use Krawfish::Koral::Document::Fields;
use Krawfish::Koral::Query::Term;
use Krawfish::Log;
use Mojo::File;
use Mojo::JSON qw/encode_json decode_json/;
use strict;
use warnings;
use List::MoreUtils qw/uniq/;

# Parses a document and creates a simple forward index list.
#
#   primary='...',
#   fields=[+field => title],
#   terms=[*term => [postings*]]
#
#   Then, when the document is added to certain nodes,
#   the keys will be translated to term_ids and the document
#   can be added with all freq_in_doc information


# TODO:
#   Don't forget to deal with TUIs!

# foundry and layer may need separated term_ids so they are exceptional small.


use constant DEBUG => 0;

# Parse the document and create an inverted index file
sub new {
  my $class = shift;

  my $self = bless {
    # sortable => {},
    stream => Krawfish::Koral::Document::Stream->new,
    fields => Krawfish::Koral::Document::Fields->new
  }, $class;

  my $doc = shift;

  unless (ref $doc) {
    $doc = decode_json(Mojo::File->new($doc)->slurp);
  };

  # Parse the document
  $self->_parse($doc);

  return $self;
};


# Get the stream object
sub stream {
  $_[0]->{stream};
};


# Get the fields object
sub fields {
  $_[0]->{fields};
};


# Translate all terms into term_ids and
# add unknown terms to the dictionary
sub identify {
  my ($self, $dict) = @_;
  $self->{fields} = $self->{fields}->identify($dict);
  $self->{stream} = $self->{stream}->identify($dict);
  return $self;
};


# Stringification
sub to_string {
  my $self = shift;
  return '[' . $self->fields->to_string . ']' . $self->stream->to_string;
};


# Parse the file and create a token-ordered document
sub _parse {
  my ($self, $doc) = @_;

  # Get the document part
  # This may - in the future - support multiple documents at once
  $doc = $doc->{document};

  my $primary = '';
  my $stream = $self->stream;
  my $fields = $self->fields;

  # Remember the primary data for the creation
  # of the forward index
  if ($doc->{primaryData}) {
    $primary = $doc->{primaryData};
  };

  # Add metadata fields
  my $pos = 0;
  # my %sortable;
  foreach my $field (@{$doc->{fields}}) {

    # TODO:
    #   Presort fields based on their field_key_id!
    #   In that way it's faster to retrieve presorted fields
    #   for enrichment!


    # Prepare field for sorting
    #if ($field->{sortable}) {

      # Which entries need to be sorted?
    #  $sortable{$field->{key}}++;
    #};


    # Prepare for summarization
    if (!$field->{type} || $field->{type} eq 'type:string') {
      if (ref $field->{value} && ref $field->{value} eq 'ARRAY') {

        if (DEBUG) {
          print_log('doc', 'Field ' . $field->{key} . ' is multivalued');
        };

        my $key = $field->{key};

        # Iterate over all field values and add the value
        foreach my $value (@{$field->{value}}) {
          $fields->add_string($key, $value);
        };
      }
      else {
        $fields->add_string($field->{key}, $field->{value});
      };
    }
    elsif ($field->{type} eq 'type:integer') {
      $fields->add_int($field->{key}, $field->{value});
    }
    elsif ($field->{type} eq 'type:store') {
      $fields->add_store($field->{key}, $field->{value});
    }
    else {
      warn 'unknown field type: ' . $field->{type};
    };

    # This will later be indexed for search as well as retrieval in
    # the forward index.
  };

  # Check that the unique field is given, as this is required
  # $self->{sortable} = \%sortable;

  my $primary_index = 0;

  # Get all subtokens
  if ($doc->{subtokens}) {

    print_log('doc', 'Parse subtokens') if DEBUG;

    # Get all subtoken offsets
    foreach my $subtoken (@{$doc->{subtokens}}) {

      # Get start and end of the subtoken
      my ($start, $end) = @{$subtoken->{offsets}};

      if (DEBUG) {
        print_log(
          'doc',
          'Store subtoken: ' . $pos . '=' . join('-', $start, $end)
        );
      };

      # Get the term surface from the primary text
      # TODO:
      #   Ensure that the offsets are valid!
      my $preceding = substr($primary, $primary_index, $start - $primary_index) // '';
      my $term      = substr($primary, $start, $end - $start);
      $primary_index = $end;

      print_log('doc', 'Surface form is ' . $term) if DEBUG;

      $stream->subtoken($pos, $preceding, $term);
      $pos++;
    };
  };


  # There are tokens indexed by subtokens
  if ($primary_index) {
    my $preceding = substr($primary, $primary_index);
    $stream->subtoken($pos, $preceding, '') if $preceding;

    # TODO: Probably not a good idea
    $primary_index = 0;
  };


  # Get all annotations
  $pos = 0;
  my $end;
  foreach my $item (@{$doc->{annotations}}) {

    # Add token term to term dictionary
    if ($item->{'@type'} eq 'koral:token') {

      unless ($item->{wrap}) {
        warn 'No wrap defined in KoralQuery';
        CORE::next;
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
      my @subtoken_offset = _subtokens($item);

      # There are no reference subtokens defined
      unless (scalar @subtoken_offset) {

        # Use the current position for storing
        push @subtoken_offset, $pos;

        # But there are offsets defined
        if ($item->{offsets}) {

          # Get character definitions
          my ($start, $end) = @{$item->{offsets}};

          # Get the term surface from the primary text
          # TODO:
          #   Ensure that the offsets are valid!
          my $preceding = substr($primary, $primary_index, $start - $primary_index);
          my $term = substr($primary, $start, $end - $start);
          $primary_index = $end;

          $stream->subtoken($pos, $preceding, $term);
        };
        $pos++;
      };

      # Add token terms
      foreach (@keys) {

        # Add token annotation
        # my $length = $subtoken_offset[1] ? ($subtoken_offset[1]-$subtoken_offset[0]-1) : 0;
        $stream->subtoken(
          $subtoken_offset[0]
        )->add_annotation($_, $subtoken_offset[1] ? $subtoken_offset[1] : $subtoken_offset[0] + 1);
      };
    }

    # Add span term to dictionary
    elsif ($item->{'@type'} eq 'koral:span') {

      # Create key string
      my $term = _term($item->{wrap});
      $term->term_type('span');

      # Add span to forward stream
      #my $length = $item->{subtokens}->[1] ? (
      #  $item->{subtokens}->[-1] - $item->{subtokens}->[0]
      #) : 0;
      $stream->subtoken($item->{subtokens}->[0])->add_annotation(
        $term,
        $item->{subtokens}->[-1] + 1
      );
    };
  };

  # There are tokens indexed by subtokens
  if ($primary_index) {
    my $preceding = substr($primary, $primary_index);
    $stream->subtoken($pos, $preceding, '') if $preceding;

    # TODO: Probably not a good idea
    $primary_index = 0;
  };
};


# TODO: Use from_koral()->term
# Potentially with a prefix
sub _term {
  my $item = shift;
  my $term = Krawfish::Koral::Query::Term->new;

  if ($item->{foundry}) {
    $term->foundry($item->{foundry});
  };

  if ($item->{layer}) {
    $term->layer($item->{layer});
  };

  if ($item->{key}) {
    $term->key($item->{key});
  };

  if ($item->{value}) {
    $term->value($item->{value});
  };

  # Make token default term type
  $term->term_type('token');

  return $term;

  #my $key = '';
  ## Create term for term dictionary
  #if ($item->{foundry}) {
  #  $key .= $item->{foundry};
  #  if ($item->{layer}) {
  #    $key .= '/' . $item->{layer};
  #  }
  #  $key .= '=';
  #};
  #return $key . ($item->{key} // '');
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


__END__



sub to_list {
  my ($self, $doc_id, $replicant_id) = @_;
};


sub add {
  # This will add the doc_id to id-field and
  # this will add the replicant field (either __1:1 or __2:node_name).
};


sub to_forward_index {
  # Only works after identification!
  # This should, however, use a K::I::Store class!
};


1;

__END__
