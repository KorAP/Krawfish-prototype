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

sub last_doc {
  $_[0]->{last_doc};
};

sub add {
  my $self = shift;
  my $doc = shift;
  unless (ref $doc) {
    $doc = decode_json slurp $doc;
  };

  # Get new doc_id
  my $doc_id = $self->{last_doc}++;

  $doc = $doc->{doc};

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

    # Create key string
    my $key = '';

    if ($item->{foundry}) {
      $key .= $item->{foundry};
      if ($item->{layer}) {
        $key .= '/' . $item->{layer};
      }
      $key .= '=';
    };
    $key .= $item->{key} // '';

    # Add term to term dictionary
    # Get post_list
    if ($item->{'@type'} eq 'koral:token') {

      my @posting = ($doc_id);

      if ($item->{segments}) {

        # Remove!
        push @posting, $item->{segments}->[0];

        if ($item->{segments}->[1]) {
          push @posting, $item->{segments}->[1];
        };
      }
      else {
        push @posting, $pos++;
      }

      my $post_list = $self->{dict}->add($key);

      # Append posting to postings list
      $post_list->append(@posting);
    }

    elsif ($item->{'@type'} eq 'koral:span') {
      $key = '<>' . $key;
      my $post_list = $self->{dict}->add($key);

      # Append posting to posting list
      $post_list->append(
        $doc_id,
        $item->{segments}->[0],
        $item->{segments}->[-1]
      );
    };
  };

  return 1;
};



sub dict {
  $_[0]->{dict};
};

1;
