package Krawfish::Index;
use Krawfish::Index::Dictionary;
use strict;
use warnings;
use Mojo::JSON qw/encode_json decode_json/;
use Mojo::Util qw/slurp/;

# TODO: Support Main Index and Auxiliary Indices with merging
# https://www.youtube.com/watch?v=98E1h_u4xGk
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

  # TODO: Get segments
  # my @segments = ();
  # if ($doc->{segments}) {
  #   foreach my $seg (@{$doc->{segments}}) {
  #     $segments[$seg->{nr}] = $seg->{offset};
  #   };
  # };

  # Get all tokens
  my $pos = 0;
  my $end;
  foreach my $item (@{$doc->{annotation}}) {

    # Add token term to term dictionary
    if ($item->{'@type'} eq 'koral:token') {

      # Create key string
      my $key = _term($item);

      # Append posting to postings list
      my @segments = _segments($item);
      push @segments, $pos++ unless scalar @segments;

      my $post_list = $self->{dict}->add($key);
      $post_list->append($doc_id, @segments);
    }

    # Add tokengroup to dictionary
    elsif ($item->{'@type'} eq 'koral:tokenGroup') {
      my @segments = _segments($item);
      push @segments, $pos++ unless scalar @segments;

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

  return 1;
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

1;
