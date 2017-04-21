package Krawfish::Index::Dynamic;
use parent 'Krawfish::Index';

# The dynamic index segment can easily
# add new documents.
# It will use the global dictionary and for
# new terms it adds them to a secondary
# dictionary.


# TODO:
#   This needs to have a different ranking
#   strategy.

sub add;

sub dynamic_dict;

sub is_dynamic { 1 };

sub is_static  { 0 };

1;
