use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Koral');

my $koral = Krawfish::Koral->new;
my $cb = $koral->corpus_builder;
my $qb = $koral->query_builder;
my $mb = $koral->compilation_builder;

$koral->corpus(
  $cb->string('author')->eq('Goethe')
);

$koral->query(
  $qb->bool_or(
    $qb->seq(
      $qb->token('aa'),
      $qb->token('bb')
    ),
    $qb->seq(
      $qb->token('aa'),
      $qb->token('cc')
    )
  )
);

$koral->compilation(
  $mb->aggregate(
    $mb->a_fields(qw/genre size/),
    $mb->a_frequencies,
    $mb->a_values('size'),
    $mb->a_length
  ),
  $mb->sort_by(
    $mb->s_field('author'),
  ),
  $mb->limit(5,20)
);

is($koral->to_segments->to_string,
   "limit(5-25:node(k=25:sort(field='id'<:sort(field='author'<:aggr(length,freq,fields:['genre','size'],values:['size']:filter((aabb)|(aacc),author=Goethe))))))",
   'Stringification');

diag 'Test normalization with nodes';

done_testing;
__END__
