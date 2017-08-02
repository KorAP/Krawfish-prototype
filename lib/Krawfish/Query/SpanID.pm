package Krawfish::Query::SpanID;
use parent 'Krawfish::Query::TermID';
use Krawfish::Index::PostingsList;
use Krawfish::Posting::Span;
use strict;
use warnings;


# TODO:
#   May be useless, if Postings can be adjusted.

# TODO: Probably rename to posting - and return a posting
# that augments the given payload
sub current {
  my $postings = $_[0]->{postings};
  return if $postings->pos == -1;
  return unless $postings->current;

  Krawfish::Posting::Span->new(
    @{$postings->current}
  );
};

1;
