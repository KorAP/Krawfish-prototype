use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Corpus::Class');
use_ok('Krawfish::Util::Bits', 'bitstring');
use_ok('Krawfish::Koral::Corpus::Builder');
use_ok('Krawfish::Index');

ok(my $class = Krawfish::Corpus::Class->new(undef, 4), 'Create class corpus');
is($class->class_string, '0000100000000000', 'Get flag');

ok($class = Krawfish::Corpus::Class->new(undef, 11), 'Create class corpus');
is($class->class_string, '0000000000010000', 'Get flag');

ok(!Krawfish::Corpus::Class->new(undef, -5), 'Create class corpus');
ok(!Krawfish::Corpus::Class->new(undef, 25), 'Create class corpus');

my $index = Krawfish::Index->new;
ok_index($index, {
  id => 2,
  author => 'David',
  integer_age => 22
} => [qw/aa bb/], 'Add complex document');
ok_index($index, {
  id => 3,
  author => 'Michael',
  integer_age => 24
} => [qw/aa bb/], 'Add complex document');
ok_index($index, {
  id => 5,
  author => 'David',
  integer_age => 24
} => [qw/aa bb/], 'Add complex document');

ok(my $cb = Krawfish::Koral::Corpus::Builder->new, 'Create CorpusBuilder');

ok(my $query = $cb->bool_or(
  $cb->class(2, $cb->string('author')->eq('David')),
  $cb->class(3, $cb->string('age')->eq('24'))
), 'Create corpus query');

ok($query->has_classes, 'Contains classes');

is($query->to_string, '{2:author=David}|{3:age=24}', 'Stringification');

is_deeply($query->to_koral_fragment, {
  'operation' => 'operation:or',
  '@type' => 'koral:fieldGroup',
  'operands' => [
    {
      'classOut' => 2,
      'operands' => [
        {
          'key' => 'author',
          'type' => 'type:string',
          'value' => 'David',
          '@type' => 'koral:field',
          'match' => 'match:eq'
        }
      ],
      '@type' => 'koral:fieldGroup',
      'operation' => 'operation:class'
    },
    {
      'classOut' => 3,
      '@type' => 'koral:fieldGroup',
      'operands' => [
        {
          'value' => '24',
          'type' => 'type:string',
          'key' => 'age',
          'match' => 'match:eq',
          '@type' => 'koral:field'
        }
      ],
      'operation' => 'operation:class'
    }
  ]
}, 'Stringification');

ok($query = $query->normalize, 'Normalize');
is($query->to_string,
   "{2:author=David}|{3:age=24}",
   'Stringification');

ok($query = $query->identify($index->dict), 'Identify');
is($query->to_string,
   "{2:#2}|{3:#13}",
   'Stringification');

ok($query = $query->optimize($index->segment), 'Planning');
is($query->to_string,
   "or(class(2:#2),class(3:#13))",
   'Stringification');

ok($query->next, 'Next match');
is($query->current->to_string, '[0!2]', 'First match');
ok($query->next, 'Next match');
is($query->current->to_string, '[1!3]', 'First match');
ok($query->next, 'Next match');
is($query->current->to_string, '[2!2,3]', 'First match');
ok(!$query->next, 'Next match');



# Query with and
ok($query = $cb->bool_and(
  $cb->class(2, $cb->string('author')->eq('David')),
  $cb->class(3, $cb->string('age')->eq('24'))
), 'Create corpus query');

ok($query->has_classes, 'Contains classes');

is($query->to_string, '{2:author=David}&{3:age=24}', 'Stringification');

ok($query = $query->normalize->identify($index->dict)->optimize($index->segment), 'Planning');
is($query->to_string,
   "and(class(3:#13),class(2:#2))",
   'Stringification');

ok($query->next, 'Next match');
is($query->current->to_string, '[2!2,3]', 'First match');
ok(!$query->next, 'Next match');


TODO: {
  local $TODO = 'Test corpus classes in queries';
  # Test optimization with ignorable options
};

done_testing;
__END__
