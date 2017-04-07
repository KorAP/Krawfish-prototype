package Krawfish::Corpus::SortFilter;
use parent 'Krawfish::Corpus';
use Krawfish::Log;
use strict;
use warnings;

# THIS IS DEPRECATED!
# USE K::R::Sort::Filter instead!

# Construct a sortfilter
sub new {
  my ($class, $query, $bucket, $ranks) = @_;

  bless {
    query       => $query,  # This is the nested query
    last_bucket => $bucket, # This is a shared value indicating
                            # the last valid bucket of the ranking
                            # with 0 meaning all valid
    ranks       => $ranks,  # A Krawfish::Index::FieldsRank object
    ascending   => 1        # Boolean for ascending order
  }, $class;
};


# Get next document that is not filtered by sort
sub next {
  my $self = shift;

  my $query = $self->{query};
  my $ranks = $self->{ranks};
  my $ascending = $self->{ascending};
  my $last_bucket = ${$self->{bucket}};

  while ($query->next) {

    # Check if the last_bucket is 0,
    # meaning - nothing to filter yet
    return 1 if $last_bucket == 0;

    # Get the current doc id
    my $doc_id = $query->current->doc_id;

    my $diff = $ranks->get($doc_id) - $last_bucket;
    
    # Check, if the bucket is irrelevant
    if ($ascending && ) {
      $self->{doc_id} = $doc_id;
      return 1;
    };
  };
};


1;
