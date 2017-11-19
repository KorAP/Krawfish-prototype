use Test::More;
use strict;
use warnings;

use_ok('Krawfish::Koral::Result::Enrich::Snippet');
use_ok('Krawfish::Koral::Result::Enrich::Snippet::Hit');
use_ok('Krawfish::Koral::Result::Enrich::Snippet::Highlight');
use_ok('Krawfish::Koral::Result::Enrich::Snippet::Span');

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

# Add annotation
my $span = Krawfish::Koral::Result::Enrich::Snippet::Span->new(
  term => Krawfish::Koral::Query::Term->new('opennlp/l=Baum'),
  start => 2,
  end => 3,
  depth => 0
);

ok($snippet->add($span), 'Add span');

done_testing;

__END__
