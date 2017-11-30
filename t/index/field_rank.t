use Test::More;
use strict;
use warnings;

use_ok('Krawfish::Index::Fields::Rank');
use_ok('Krawfish::Index::Dictionary::Collation');

my $rank;
my $coll;


ok($rank = Krawfish::Index::Fields::Rank->new('NUM'), 'Create new rank');

# Add value => doc_id
ok($rank->add(7, 1), 'Add a single value');
ok($rank->add(4, 2), 'Add a single value');
ok($rank->add(5, 3), 'Add a single value');
ok($rank->add(4, 4), 'Add a single value');
ok($rank->add(8, 2), 'Add a multivalue');

# There are now 4 values with 4 doc_ids.
# One value is given twice.
# One doc is defined twice.
is($rank->max_rank, 0, 'Max rank');

is($rank->to_string, '{7:1;4:2;5:3;4:4;8:2}', 'Buffer');

ok($rank->commit, 'Add new values');

is($rank->to_string, '<4:2,4;5:3;7:1;8:2>', 'Buffer');

is($rank->max_rank, 4, 'Max rank');

# Sorting is: [4=>[2,4]][5=>[3]][7=>[1]][8=>[2]]
# Rank 4 is not given in asc
is($rank->asc_rank_for(2), 1, 'Rank for doc_id');
is($rank->asc_rank_for(4), 1, 'Rank for doc_id');
is($rank->asc_rank_for(3), 2, 'Rank for doc_id');
is($rank->asc_rank_for(1), 3, 'Rank for doc_id');

# Get the values by rank
is($rank->asc_key_for(1), 4, 'Key for rank');
is($rank->asc_key_for(2), 5, 'Key for rank');
is($rank->asc_key_for(3), 7, 'Key for rank');
is($rank->asc_key_for(4), 8, 'Key for rank');

# Sorting is: [8=>[2]][7=>[1]][5=>[3]][4=>[2,4]]
is($rank->desc_rank_for(2), 1, 'Rank for doc_id');
is($rank->desc_rank_for(1), 2, 'Rank for doc_id');
is($rank->desc_rank_for(3), 3, 'Rank for doc_id');
is($rank->desc_rank_for(4), 4, 'Rank for doc_id');

# Get the values by rank
is($rank->desc_key_for(1), 8, 'Key for rank');
is($rank->desc_key_for(2), 7, 'Key for rank');
is($rank->desc_key_for(3), 5, 'Key for rank');
is($rank->desc_key_for(4), 4, 'Key for rank');

# Create new object with german collation
$coll = Krawfish::Index::Dictionary::Collation->new('DE');
ok($rank = Krawfish::Index::Fields::Rank->new($coll), 'Create new rank');

# Add value => doc_id
# 'Goethe'=>[1,4],'Heine'=>[2],'Herder'=>[3],'Schiller'=>[2]
ok($rank->add('Goethe', 1), 'Add a single value');
ok($rank->add('Schiller', 2), 'Add a single value');
ok($rank->add('Herder', 3), 'Add a single value');
ok($rank->add('Goethe', 4), 'Add a single value');
ok($rank->add('Heine', 2), 'Add a multivalue'); # Heine + Schiller

ok($rank->commit, 'Add new values');

is($rank->asc_rank_for(1), 1, 'Asc rank');
is($rank->asc_rank_for(4), 1, 'Asc rank');
is($rank->asc_rank_for(2), 2, 'Asc rank');
is($rank->asc_rank_for(3), 3, 'Asc rank');

# 'Schiller'=>[2],'Herder'=>[3],'Heine'=>[2],'Goethe'=>[1,4]
is($rank->desc_rank_for(1), 4, 'Desc rank');
is($rank->desc_rank_for(4), 4, 'Desc rank');
is($rank->desc_rank_for(2), 1, 'Desc rank');
is($rank->desc_rank_for(3), 2, 'Desc rank');


# 'Goethe'=>[1,4],'Heine'=>[2],'Herder'=>[3],'Schiller'=>[2]
is($rank->asc_key_for(1), $coll->sort_key('Goethe'), 'Asc key');
is($rank->asc_key_for(2), $coll->sort_key('Heine'), 'Asc key');
is($rank->asc_key_for(3), $coll->sort_key('Herder'), 'Asc key');
is($rank->asc_key_for(4), $coll->sort_key('Schiller'), 'Asc key');

is($rank->desc_key_for(4), $coll->sort_key('Goethe'), 'Asc key');
is($rank->desc_key_for(3), $coll->sort_key('Heine'), 'Asc key');
is($rank->desc_key_for(2), $coll->sort_key('Herder'), 'Asc key');
is($rank->desc_key_for(1), $coll->sort_key('Schiller'), 'Asc key');


# Add new value!
# 'Goethe'=>[1,4],'Heine'=>[2],'Herder'=>[3],'Schiller'=>[2]
ok($rank->add('Goethe', 5), 'Add a single value');
is($rank->asc_rank_for(5), 0, 'Asc rank');
ok($rank->commit, 'Commit new field');
is($rank->asc_rank_for(5), 1, 'Asc rank');


# test with doc_id = 0
ok($rank = Krawfish::Index::Fields::Rank->new('NUM'), 'Create new rank');

# Add value => doc_id
ok($rank->add(7, 1), 'Add a single value');
ok($rank->add(4, 2), 'Add a single value');
ok($rank->add(5, 0), 'Add a single value');
ok($rank->add(4, 4), 'Add a single value');

ok($rank->commit, 'Commit to field rank');

# Ranks:
# 4 => [2,4], 5 => [0], 7 => [1]
is($rank->asc_key_for(1), 4, 'Get key');
is($rank->asc_key_for(2), 5, 'Get key');
is($rank->asc_key_for(3), 7, 'Get key');

# 4,2;0;1
# [2][3][1][][1]
is($rank->asc_rank_for(0), 2, 'Get rank for doc-id');
is($rank->asc_rank_for(1), 3, 'Get rank for doc-id');
is($rank->asc_rank_for(2), 1, 'Get rank for doc-id');
is($rank->asc_rank_for(3), 0, 'Get rank for doc-id');
is($rank->asc_rank_for(4), 1, 'Get rank for doc-id');


ok($rank->add(5 => 3), 'Add document');
ok($rank->add(7 => 5), 'Add document');
is($rank->to_string,'<4:2,4;5:0;7:1>{5:3;7:5}', 'Stringification');

ok($rank->commit, 'Commit');
is($rank->asc_key_for(3), 7, 'Get key');

is($rank->to_string,'<4:2,4;5:0,3;7:1,5>', 'Stringification');


# Create new object with german collation
ok($rank = Krawfish::Index::Fields::Rank->new('NUM'), 'Create new rank');

ok($rank->add(9, 0), 'Add a single value');
ok($rank->add(5, 1), 'Add a single value');
ok($rank->add(2, 2), 'Add a single value');
ok($rank->add(3, 3), 'Add a single value');
ok($rank->add(7, 4), 'Add a single value');
ok($rank->add(3, 5), 'Add a single value');
ok($rank->add(7, 6), 'Add a single value');
ok($rank->add(7, 7), 'Add a single value');

#is($rank->to_string, '<?:2;?:3;?:1;?:4;?:0>{?:5;?:6;?:7}', 'Stringification');
ok($rank->commit, 'Commit data');
# Abraham:1:[2];Fritz:2:[3,5];Julian:3:[1];Michael:4:[4,6,7];Peter:5:[0]
is($rank->to_string, '<2:2;3:3,5;5:1;7:4,6,7;9:0>', 'Stringification');
# ?:2;?:3,5;?:1;?:4,6;?:7;?:0
is($rank->to_asc_string, '[5][3][1][2][4][2][4][4]', 'Rank string');


# Create new object with german collation
$coll = Krawfish::Index::Dictionary::Collation->new('DE');
ok($rank = Krawfish::Index::Fields::Rank->new($coll), 'Create new rank');

ok($rank->add('Peter', 0), 'Add a single value');
ok($rank->add('Julian', 1), 'Add a single value');
ok($rank->add('Abraham', 2), 'Add a single value');
ok($rank->add('Fritz', 3), 'Add a single value');
ok($rank->add('Michael', 4), 'Add a single value');
ok($rank->commit, 'Commit data');
ok($rank->add('Fritz', 5), 'Add a single value');
ok($rank->add('Michael', 6), 'Add a single value');
ok($rank->add('Michael', 7), 'Add a single value');

is($rank->to_string,
   '<GQw..A==:2;Gak..wAA:3;GhA..AA=:1;Gm4..A==:4;Gs4..wAA:0>'.
     '{Gak..wAA:5;Gm4..A==:6;Gm4..A==:7}', 'Stringification');

ok($rank->commit, 'Commit data');
# Abraham:1:[2];Fritz:2:[3,5];Julian:3:[1];Michael:4:[4,6,7];Peter:5:[0]
is($rank->to_string,
   '<GQw..A==:2;Gak..wAA:3,5;GhA..AA=:1;Gm4..A==:4,6,7;Gs4..wAA:0>',
   'Stringification');

# ?:2;?:3,5;?:1;?:4,6;?:7;?:0
is($rank->to_asc_string, '[5][3][1][2][4][2][4][4]', 'Rank string');


done_testing;
__END__
