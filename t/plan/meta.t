use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Koral');
use_ok('Krawfish::Index');

my $index = Krawfish::Index->new;

ok_index($index, '<1:opennlp/c=NP>[Der][hey]</1>', 'Add new document');

ok(my $koral = Krawfish::Koral->new, 'New Koral');

# Simple query definition
my $builder = $koral->query_builder;
$koral->query(
  $builder->seq(
    $builder->token('Der'),
    $builder->span('opennlp/c=NP')
  )
);

is($koral->to_string, '[Der]<opennlp/c=NP>');

diag 'Meta normalization not implemented yet';

done_testing;
__END__



# Simple meta definition
$koral->meta(
  $koral->meta_builder->items_per_page(3)->field_sort_asc_by('author')
);

ok($koral = $koral->normalize, 'Normalization');

#is($koral->prepare_for($index)->to_string,
is($koral->to_string,
   q!resultLimit([0-3]:resultSorted(['author'<,'id'<],0-3:constr(pos=2:'Der','<>opennlp/c=NP')))!,
   'Stringification');




# Meta definition with start index
$koral->meta(
  $koral->meta_builder->items_per_page(5)->start_index(2)->field_sort_asc_by('author')
);



is($koral->prepare_for($index)->to_string,
   q!resultLimit([2-7]:resultSorted(['author'<,'id'<],0-7:constr(pos=2:'Der','<>opennlp/c=NP')))!,
   'Stringification');

# Meta definition with facets
$koral->meta(
  $koral->meta_builder->facets('author')->start_index(2)->field_sort_asc_by('author')
);

is($koral->prepare_for($index)->to_string,
   q!resultLimit([2-]:resultSorted(['author'<,'id'<]:aggregate([facet:'author']:constr(pos=2:'Der','<>opennlp/c=NP'))))!,
   'Stringification');

# Meta definition with facets (different order)
$koral->meta(
  $koral->meta_builder->start_index(2)->facets('author')->field_sort_asc_by('author')
);

is($koral->prepare_for($index)->to_string,
   q!resultLimit([2-]:resultSorted(['author'<,'id'<]:aggregate([facet:'author']:constr(pos=2:'Der','<>opennlp/c=NP'))))!,
   'Stringification');


# Meta definition with count
$koral->meta(
  $koral->meta_builder->count(1)
);

is($koral->prepare_for($index)->to_string,
   q!resultSorted(['id'<]:aggregate([count]:constr(pos=2:'Der','<>opennlp/c=NP')))!,
   'Stringification');


# Meta definition with length
$koral->meta(
  $koral->meta_builder->length(1)
);

is($koral->prepare_for($index)->to_string,
   q!resultSorted(['id'<]:aggregate([length]:constr(pos=2:'Der','<>opennlp/c=NP')))!,
   'Stringification');


done_testing;
__END__
