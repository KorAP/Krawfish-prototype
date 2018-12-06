use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Koral::Corpus::Builder');

ok(my $cb = Krawfish::Koral::Corpus::Builder->new, 'Create CorpusBuilder');

my $cq = $cb->bool_or(
  $cb->date('pub_date')->geq('2015-03'),
  $cb->class(
    $cb->bool_and(
      $cb->string('author')->eq('Nils'),
      $cb->regex('doc_id')->eq('WPD.*')
    ),
    2
  )
);

is($cq->to_string, 'pub_date>=2015-03|{2:doc_id=WPD.*&author=Nils}');
ok($cq = $cq->normalize, 'Normalization');
is($cq->to_string, 'pub_date&=[[2015-03--2200]]|{2:doc_id=WPD.*&author=Nils}');


# Simplify class
$cq = $cb->bool_or(
  $cb->class(
    $cb->string('author')->eq('Nils'),
    2
  ),
  $cb->class(
    $cb->regex('doc_id')->eq('WPD.*'),
    2
  )
);

is($cq->to_string, '{2:author=Nils}|{2:doc_id=WPD.*}');
ok($cq = $cq->normalize, 'Normalization');
is($cq->to_string, '{2:doc_id=WPD.*|author=Nils}');

done_testing;
