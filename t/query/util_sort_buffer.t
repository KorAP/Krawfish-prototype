#!/url/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Krawfish::Query::Base::Sorted');
use_ok('Krawfish::Index::PostingsList');

my $list = Krawfish::Index::PostingsList->new('index.org', 'baum', 1);
# $list->append(start,end, payload);

# my $buf = Krawfish::Query::Base::Sorted->new(10);

done_testing;
__END__

1;

