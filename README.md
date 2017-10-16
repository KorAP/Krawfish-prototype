![Krawfish Prototype](https://raw.githubusercontent.com/KorAP/Krawfish-Prototype/master/misc/krawfish-prototype.png)

The Krawfish Prototype is a testbed search backend for KorAP,
to implement design concepts both for Kanalito and Krill.

Krawfish Prototype focusses on
- Patterns for distribution
  (data aggregation, sorting, grouping ...)
- Implementation of a forward index
- Normalization and optimization of complex queries
- Implementation of experimental features

Krawfish Prototype is still work in progress.
The segment handling of Krawfish is based on Krill and therefore
heavily inspired by Lucene and Lucy.

**! This software is in its early stages and not stable yet! Use it on your own risk!**

## SETUP

Krawfish Prototype requires Perl of at least v5.10.1.
The recommended environment is based on [Perlbrew](http://perlbrew.pl/)
with [App::cpanminus](http://search.cpan.org/~miyagawa/App-cpanminus/).

```
$ git clone https://github.com/KorAP/Krawfish-Prototype
$ cd Krawfish-Prototype
$ cpanm --installdeps .
$ perl Makefile.PL
$ make test
```

## SYNOPSIS

```
use Krawfish::Koral;
use Krawfish::Index;

# Add documents to index
my $index = Krawfish::Index->new;
$index->introduce_field('docID' => 'de_DE');
$index->add_doc('t/data/doc1.jsonld');
$index->add_doc('t/data/doc2.jsonld');
$index->commit;

# Start KoralQuery object
my $koral = Krawfish::Koral->new;

# Define a query
# [einen|"d.*"][][Hut]
my $query = $koral->query_builder;
$koral->query(
  $query->seq(
    $query->token(
      $query->bool_or(
        'einen',
        $query->term_re('d.*')
      )
    ),
    $query->anywhere,
    $query->term('Hut')
  )
);

# Define a virtual corpus
my $corpus = $koral->corpus_builder;
$koral->corpus(
  $corpus->bool_and(
    $corpus->string('license=free'),
    $corpus->string('corpus=corpus-2')
  )
);

# Define a compilation target
my $compile = $koral->compile_builder;
$koral->compile(
  $compile->aggregate(
    $compile->a_fields('license'),
    $compile->a_frequencies
  ),
  $compile->enrich(
    $compile->e_fields('textLength')
  ),
  $compile->sort_by(
    $compile->s_field('docID')
  )
);

# Execute KoralQuery
my $request = $koral->to_query
  ->identify($index->dict)
  ->optimize($index->segment);

if ($request->next) {
  print $request->current_match->to_string;
};

```

## COPYRIGHT AND LICENSE

Copyright (C) 2017, [IDS Mannheim](http://www.ids-mannheim.de/)<br>
Author: [Nils Diewald](http://nils-diewald.de/)

Krawfish Prototype is free software published under the
[BSD-2 License](https://raw.githubusercontent.com/KorAP/Krawfish-Prototype/master/LICENSE).