package Krawfish::Koral::Result::Inflatable;
use strict;
use warnings;
use Role::Tiny;

requires qw/inflate
            to_string
            to_koral_fragment/;

1;
