package Krawfish::Query::Span;
use parent 'Krawfish::Query::Term';
use Krawfish::Index::PostingsList;
use Krawfish::Posting::Span;
use strict;
use warnings;

# TODO: Store elements with the length of the elements
# in segments instead of the end position!

# TODO: Probably rename to posting - and return a posting
# that augments the given payload
sub current {
  my $postings = $_[0]->{postings};
  return if $postings->pos == -1;
  return unless $postings->posting;

  Krawfish::Posting::Span->new(
    @{$postings->posting}
  );
};


1;
