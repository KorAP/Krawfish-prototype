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

  my $pos = 0;

  # Get new doc_id
  my $doc_id = $self->{last_doc}++;

  # Get all tokens
  foreach my $token (@{$doc->{doc}->{annotation}}) {

    # Add term to term dictionary
    # Get post_list
    my $post_list = $self->{dict}->add($token->{key});

    # Append posting to postings list
    $post_list->append(
      $doc_id, $pos
    );

    # Step to next token position
    $pos++;
  };

  return 1;
};

sub dict {
  $_[0]->{dict};
};

1;
