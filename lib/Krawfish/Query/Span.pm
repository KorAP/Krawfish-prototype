package Krawfish::Query::Token;
use Krawfish::Index::PostingsList;
use Krawfish::Posting::Token;
use strict;
use warnings;

# TODO: Store elements with the length of the elements
# in segments instead of the end position!

sub new {
  my ($class, $index, $term) = @_;
  my $postings = $index->dict->get('<>' . $term)
    // Krawfish::Index::PostingsList->new($index, $term);
  bless {
    postings => $postings,
    term => $term
  }, $class;
};

1;
