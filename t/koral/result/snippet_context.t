use Test::More;
use Test::Krawfish;
use Krawfish::Util::Constants qw/:PREFIX/;
use strict;
use warnings;
use utf8;

use_ok('Krawfish::Koral::Result::Enrich::Snippet');
use_ok('Krawfish::Koral::Result::Enrich::Snippet::Hit');
use_ok('Krawfish::Koral::Result::Enrich::Snippet::Highlight');
use_ok('Krawfish::Koral::Result::Enrich::Snippet::Span');
use_ok('Krawfish::Koral::Result::Enrich::Snippet::Context');
use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Document::Stream');
use_ok('Krawfish::Koral::Document::Subtoken');
use_ok('Krawfish::Koral::Query::Term');

my $index = Krawfish::Index->new;

ok_index_file($index, 'doc1.jsonld', 'Add new document');

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


# Create snippet object
my $snippet = Krawfish::Koral::Result::Enrich::Snippet->new(
  doc_id => 5,
  stream => $stream
);


# Create hit object
my $hit = Krawfish::Koral::Result::Enrich::Snippet::Hit->new(
  start => 1,
  start_char => -1,
  end => 4
);

ok($snippet->add($hit), 'Add left context');

# Left context
my $context_left = Krawfish::Koral::Result::Enrich::Snippet::Context->new(
  left => 1
);

ok($snippet->add($context_left), 'Add left context');

is(
  $snippet->inflate($index->dict)->to_html,
  '<span class="context-left">Der</span><span class="match"><mark> alte Mann ging</mark></span> über die Straße',
  'Render with context');

# Right context
my $context_right = Krawfish::Koral::Result::Enrich::Snippet::Context->new(
  # End marker is irrelevant, as the context ends when the first element starts
  left => 0,
  more => 1
);

ok($snippet->add($context_right), 'Add right context');

is(
  $snippet->inflate($index->dict)->to_html,
  '<span class="context-left">Der</span><span class="match"><mark> alte Mann ging</mark></span><span class="context-right"> über die Straße<span class="more"></span></span>',
  'Render with context');



done_testing;
__END__
