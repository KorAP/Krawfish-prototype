package Krawfish::Query::Constraint::Base;
use strict;
use warnings;
use Role::Tiny;

requires qw/clone
            check
            to_string/;

1;
