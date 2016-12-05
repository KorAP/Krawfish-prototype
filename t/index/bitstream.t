package Krawfish::Index::BitStream::Finger;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless {
    stream => shift,
    finger => -1
  }, $class;
};

package main;
use Krawfish::Index::Postings::Span;
use Test::More;
use strict;
use warnings;
use Data::Dumper;

my $spans = Krawfish::Index::Postings::Span->new;

$spans->add(
  45, # doc_id
  20, # start
  23, # end
  0   # depth
);

is($spans->stream, pack("L",45).'[20:3:0]', 'Stream');

my ($offset, $data) = $spans->get(0);
is_deeply($data, [45,20,23,0], 'Get entry');

$spans->add(
  80, # doc_id
  17, # start
  20, # end
  2   # depth
);

($offset, $data) = $spans->get($offset);
is_deeply($data, [80,17,20,2], 'Get entry');

# my $stream = Krawfish::Index::BitStream::Finger->new($spans);

done_testing;
