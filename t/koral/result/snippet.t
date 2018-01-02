use Test::More;
use Test::Krawfish;
use strict;
use warnings;
use utf8;

use_ok('Krawfish::Koral::Result::Enrich::Snippet');
use_ok('Krawfish::Koral::Result::Enrich::Snippet::Hit');
use_ok('Krawfish::Koral::Result::Enrich::Snippet::Highlight');
use_ok('Krawfish::Koral::Result::Enrich::Snippet::Span');
use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Document::Stream');
use_ok('Krawfish::Koral::Document::Subtoken');

my $index = Krawfish::Index->new;

ok_index_file($index, 'doc1.jsonld', 'Add new document');

# Create snippet object
my $snippet = Krawfish::Koral::Result::Enrich::Snippet->new(
  doc_id => 5
);

# Create hit object
my $hit = Krawfish::Koral::Result::Enrich::Snippet::Hit->new(
  start => 1,
  end => 4
);

ok($snippet->add($hit), 'Add hit');

is($snippet->hit_start, 1, 'Hit start');
is($snippet->hit_end, 4, 'Hit end');

my $highlight = Krawfish::Koral::Result::Enrich::Snippet::Highlight->new(
  start => 2,
  end => 3,
  number => 4
);

ok($snippet->add($highlight), 'Add highlight');

my $stream = Krawfish::Koral::Document::Stream->new;

# Initialize forward pointer
my $fwd = $index->segment->forward->pointer;
$fwd->next;

foreach (0..6) {
  my $current = $fwd->current;
  $stream->subtoken($_ => Krawfish::Koral::Document::Subtoken->new(
    preceding_enc => $current->preceding_data,
    subterm_id => $current->term_id
  ));

  $fwd->next;
};

ok($snippet->stream($stream));

is($snippet->inflate($index->dict)->to_string, 'snippet:Der [alte {4:Mann} ging] über die Straße');

diag 'Check preceding data';

done_testing;
__END__


# Add annotation
my $span = Krawfish::Koral::Result::Enrich::Snippet::Span->new(
  term => Krawfish::Koral::Query::Term->new('opennlp/l=Baum'),
  start => 2,
  end => 3,
  depth => 0
);

ok($snippet->add($span), 'Add span');
