#!/url/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Krawfish::Util::BucketSort');

ok(my $sorter = Krawfish::Util::BucketSort->new(20, 500), 'Create bucket sorter');

# Temporary:
is(17, Krawfish::Util::BucketSort::_temp_bucket_nr(34,500), 'bucket calc 16');
is(255, Krawfish::Util::BucketSort::_temp_bucket_nr(500,500), 'bucket calc 255');
is(255, Krawfish::Util::BucketSort::_temp_bucket_nr(499,500), 'bucket calc 255');
is(1, Krawfish::Util::BucketSort::_temp_bucket_nr(2,500), 'bucket calc 0');
is(0, Krawfish::Util::BucketSort::_temp_bucket_nr(1,500), 'bucket calc 0');

# TODO: Use big endian notation: pack('l', 44)

ok($sorter = Krawfish::Util::BucketSort->new(5, 30_000), 'Create bucket sorter');

# TODO: This may change when optimized, so more records
#   may be accepted before cleanup takes place
ok( $sorter->add(20,     'Baum 1'),  'Add record to sorter - 0');
ok( $sorter->add(44,     'Baum 2'),  'Add record to sorter - 0');
ok( $sorter->add(4_000,  'Baum 3'),  'Add record to sorter - 34');
ok( $sorter->add(18_000, 'Baum 4'),  'Add record to sorter - 153');
ok( $sorter->add(25_000, 'Baum 5'),  'Add record to sorter - 213');

ok(!$sorter->add(26_000, 'Baum 6'),  'Not relevant any more');

# print $sorter->to_histogram;

done_testing;
__END__

ok( $sorter->add(5,      'Baum 7'),  'Add record to sorter - 0');
ok(!$sorter->add(32_000, 'Baum 8'),  'Not relevant any more');
ok( $sorter->add(15_000, 'Baum 9'),  'Add record to sorter - 127');

done_testing;
__END__

ok( $sorter->add(15_000, 'Baum 10'), 'Add record to sorter - 127');
ok(!$sorter->add(20_000, 'Baum 11'), 'Not relevant any more');
ok( $sorter->add(5,      'Baum 12'),  'Add record to sorter - 0');

ok($sorter->next, 'Get first element');
is($sorter->current->[1], 'Baum 7', 'Get first entry');


done_testing;
