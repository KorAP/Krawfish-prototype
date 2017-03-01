#!/url/bin/env perl
use strict;
use warnings;
use Test::More;
use Data::Dumper;

use_ok('Krawfish::Util::PriorityQueue::PerDoc');

my $max_rank = 800_000;
my $max_rank_ref = \$max_rank;

ok(my $sorter = Krawfish::Util::PriorityQueue::PerDoc->new(5, $max_rank_ref), 'Create priority sorter');

sub node {
  return [
    $_[0], # RANK
    0,     # SAME
    $_[2], # VALUE
    $_[1], # IN_DOC
    0      # IN_DOC_COMPLETE
  ]
};

ok( $sorter->insert(node(20, 2, 'Baum 1; Baum2')),  'Add records to sorter - 20/2');


done_testing;
__END__
