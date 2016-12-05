use Krawfish::Index::Stream::Finger;
use Krawfish::Index::Stream::Span;
use Test::More;
use strict;
use warnings;
use Data::Dumper;

my $spans = Krawfish::Index::Stream::Span->new;

$spans->add(
  45, # doc_id
  20, # start
  23, # end
  0   # depth
);

is($spans->raw, pack("L",45).'[20:3:0]', 'Stream');

my $finger = Krawfish::Index::Stream::Finger->new($spans);

ok($finger->next, 'Finger points to next');
my $current = $finger->current;
is($current->doc_id, 45, 'Doc ID');
is($current->start, 20, 'Start');
is($current->end, 23, 'End');

$spans->add(
  80, # doc_id
  17, # start
  20, # end
  2   # depth
);


ok($finger->next, 'Finger points to next');
$current = $finger->current;
is($current->doc_id, 80, 'Doc ID');
is($current->start, 17, 'Start');
is($current->end, 20, 'End');

done_testing;
