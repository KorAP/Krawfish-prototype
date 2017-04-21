package Krawfish::Index::Static;
use parent 'Krawfish::Index';

# Multiple static index segments can
# only delete documents (by adding entries
# to the deleted documents posting list),
# but not add new documents.
# But static documents can be merged
# (with static segments and with the dynamic
# segment).

sub new;

# This will use Krawfish::Index::Merge
sub merge;

sub is_dynamic { 0 };
sub is_static  { 1 };

1;
