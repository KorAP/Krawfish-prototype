use 5.010001;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  VERSION_FROM => 'lib/Krawfish.pm',
  ABSTRACT     => 'Prototype Backend for KorAP',
  NAME         => 'Krawfish',
  AUTHOR       => 'Nils Diewald',
  BUILD_REQUIRES => {
    'Test::More' => 0
  },
  PREREQ_PM => {
    'Mojolicious' => '7.23',
    'Scalar::Util' => 0,
    'Data::BitStream' => 0,
    'Role::Tiny' => '2.000005',
    'Unicode::CaseFold' => 0,
    'Unicode::Normalize' => 0,
    'Scalar::Util' => 0,
    'List::MoreUtils' => 0,
    'List::Util' => 0,
    'Test::More' => 0,
    'Memoize' => 0,
    'Unicode::Collate::Locale' => 0
  },
  test => {
    TESTS => 't/*.t t/**/*.t'
  }
);
