package Krawfish::Koral::Compile::Node::Group;
use strict;
use warnings;
use Role::Tiny;

requires qw/to_string
            identify
            optimize/;

1;
