package Krawfish::Index::Segment;
use Krawfish::Index::Subtokens;
use Krawfish::Index::PrimaryData;
use Krawfish::Index::Fields;
use Krawfish::Index::PostingsLive;
use Krawfish::Cache;
use Krawfish::Log;
use Scalar::Util qw!blessed!;
use strict;
use warnings;

# Return segment information for term ids
# This is the base for dynamic and
# static segment stores.



use constant DEBUG => 1;

sub new {
  my $class = shift;
  my $file = shift;
  my $self = bless {
    file => $file
  }, $class;

  print_log('segment', 'Instantiate new segment') if DEBUG;

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

1;
