package Krawfish::Query::Term;
use Krawfish::Index::PostingsList;
use Krawfish::Posting::Token;
use strict;
use warnings;

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

  print '  >> Next "' . $self->term . "\"";

  # TODO: This should respect filters
  my $return = $self->{postings}->next;
  if ($return) {
    print ' - current is ' . $self->current . "\n";
  }
  else  {
    print " - no current\n";
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
