use strict;
use warnings;
use utf8;
use Test::More;
use Krawfish::Util::Constants qw/:PREFIX :RANGE/;
use Test::Krawfish;
use Data::Dumper;

use_ok('Krawfish::Koral::Document');
use_ok('Krawfish::Index');

ok(my $doc = Krawfish::Koral::Document->new(
  {
    '@context' => 'http://korap.ids-mannheim.de/ns/koral/0.5/context.jsonld',
    document => {
      '@type' => 'koral:document',
      'primaryData' => '',
      'id' => 7,
      fields => [
        {
          '@type' => "koral:field",
          key => "pubDate",
          value => "2018-04",
          type => "type:date"
        }
      ],
    }
  }
), 'Load document');

is($doc->fields->to_string, "'pubDate'=2018-04");

my @terms = $doc->fields->operands->[0]->to_range_terms;

is($terms[0], DATE_FIELD_PREF . 'pubDate:2018-04' . RANGE_ALL_POST);
is($terms[1], DATE_FIELD_PREF . 'pubDate:2018' . RANGE_PART_POST);

ok($doc = Krawfish::Koral::Document->new(
  {
    '@context' => 'http://korap.ids-mannheim.de/ns/koral/0.5/context.jsonld',
    document => {
      '@type' => 'koral:document',
      'primaryData' => '',
      'id' => 7,
      fields => [
        {
          '@type' => "koral:field",
          key => "pubDate",
          from => "2016-02",
          to => "2018-04",
          type => "type:date"
        }
      ]
    }
  }), 'Index with date range');

is($doc->fields->to_string, "'pubDate'=2016-02--2018-04");

# @terms = $doc->fields->operands->[0]->to_range_terms;


done_testing;
