use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Compile::Segment::Enrich::Snippet::Spans');

my $spans = Krawfish::Compile::Segment::Enrich::Snippet::Spans->new;

$spans->add_text('Der')->add_text(' ')->add_text('alte');

is($spans->to_html, 'Der alte', 'HTML');


done_testing;

1;
