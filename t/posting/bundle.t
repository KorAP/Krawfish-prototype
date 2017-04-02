use Test::More;
use strict;
use warnings;

use_ok('Krawfish::Posting::Bundle');
use_ok('Krawfish::Posting::Match');

my $match = Krawfish::Posting::Match->new(
  doc_id => 1,
  start => 2,
  end => 5
);

my $matches = Krawfish::Posting::Bundle->new($match);

is($matches->to_string, '[[1:2-5]]', 'Stringification');

ok($matches->add(Krawfish::Posting::Match->new(doc_id => 3, start => 5, end => 6)), 'Add');

is($matches->to_string, '[[1:2-5]|[3:5-6]]', 'Stringification');

done_testing;
