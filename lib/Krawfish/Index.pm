package Krawfish::Index;
use Krawfish::Index::Dictionary;
use Krawfish::Index::Offsets;
use Krawfish::Index::PrimaryData;
use strict;
use warnings;
use Scalar::Util qw!blessed!;
use Mojo::JSON qw/encode_json decode_json/;
use Mojo::Util qw/slurp/;

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


# Get offsets
sub offsets {
  $_[0]->{offsets};
};


# Get primary
sub primary {
  $_[0]->{primary};
};


# Add document to the index
sub add {
  my $self = shift;
  my $doc = shift;
  unless (ref $doc) {
    $doc = decode_json slurp $doc;
  };

  # Get new doc_id
  my $doc_id = $self->{last_doc}++;

  # Get document
  $doc = $doc->{text};

  # Store primary data
  $self->primary->store($doc_id, $doc->{content});

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

  # Get all tokens
  $pos = 0;
  my $end;
  foreach my $item (@{$doc->{annotation}}) {

    # Add token term to term dictionary
    if ($item->{'@type'} eq 'koral:token') {

      # Create key string
      my $key = _term($item);

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

      my $post_list = $self->{dict}->add($key);
      $post_list->append($doc_id, @segments);
    }

    # Add tokengroup to dictionary
    elsif ($item->{'@type'} eq 'koral:tokenGroup') {
      my @segments = _segments($item);

      unless (scalar @segments) {
        push @segments, $pos;
        # Store offsets
        if ($item->{offsets}) {
          $offsets->store($doc_id, $pos, @{$item->{offsets}});
        };
        $pos++;
      };

      # Add tokens of token group
      foreach my $token (@{$item->{'wrap'}}) {
        my $key = _term($token);
        my $post_list = $self->{dict}->add($key);
        $post_list->append($doc_id, @segments);
      }
    }

    # Add span term to dictionary
    elsif ($item->{'@type'} eq 'koral:span') {

      # Create key string
      my $key = '<>' . _term($item);

      my $post_list = $self->{dict}->add($key);

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


sub apply {
  my $self = shift;
  my $koral = shift;

  # Necessary for filtering
  my $corpus = $koral->corpus->plan($self) or return;

  my $query = $koral->query->plan($self) or return;

  # Get meta information
  my $meta = $koral->meta->plan($self) or return;

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

sub apply {
  my $self = shift;
  $self->{index} = shift;
};


sub filter_by {
  my $self = shift;
  $self->{filter} = shift;
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
