package Krawfish::Query::Term;
use parent 'Krawfish::Query';
use Krawfish::Index::PostingsList;
use Krawfish::Posting::Token;
use Krawfish::Log;
use strict;
use warnings;

# TODO: Support filters and skip

use constant DEBUG => 0;

sub new {
  my ($class, $index, $term) = @_;
  my $postings = $index->dict->get($term)
    // Krawfish::Index::PostingsList->new($index, $term);
  bless {
    postings => $postings,
    term => $term
  }, $class;
};

# Skip to next position
# This will initialize the posting list
sub next {
  my $self = shift;

  print_log('term', 'Next "' . $self->term . "\"") if DEBUG;

  # TODO: This should respect filters
  my $return = $self->{postings}->next;
  if (DEBUG) {
    print_log('term', ' - current is ' . $self->current) if $return;
    print_log('term', ' - no current');
  };
  return $return;
};

sub term {
  $_[0]->{term};
};

# TODO: Probably rename to posting - and return a posting
# that augments the given payload
sub current {
  my $postings = $_[0]->{postings};
  return if $postings->pos == -1;
  return unless $postings->posting;

  Krawfish::Posting::Token->new(
    @{$postings->posting}
  );
};

sub freq {
  $_[0]->{postings}->freq;
};

sub to_string {
  return "'" . $_[0]->term . "'";
};

1;

__END__
