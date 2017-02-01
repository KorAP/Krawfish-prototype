use 5.010001;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  VERSION_FROM => 'lib/Krawfish.pm',
  ABSTRACT     => 'Experimental Backend for KorAP',
  NAME         => 'Krawfish',
  AUTHOR       => 'Nils Diewald',
  BUILD_REQUIRES => {
    'Test::More' => 0
  },
  PREREQ_PM => {
    'Mojolicious' => '7.23',
    'Scalar::Util' => 0
  },
  test => {
    TESTS => 't/*.t t/**/*.t'
  }
);
