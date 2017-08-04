use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral');

TODO: {
  local $TODO = 'Check this when snippets are ready';
};


done_testing;
__END__

use_ok('Krawfish::Index');
use_ok('Krawfish::Result::Segment::Enrich::Snippet::Highlights');

my $index = Krawfish::Index->new;
ok_index($index, [qw/aa bb aa bb/], 'Add new document');

my $highlights = Krawfish::Result::Segment::Enrich::Snippet::Highlights->new(
  [2,3] => $index->subtokens
);

my $posting = Krawfish::Posting->new(
  doc_id => 0,
  start => 1,
  end => 2
);


ok(my $stack = $highlights->process($posting), 'Parse');



done_testing;
