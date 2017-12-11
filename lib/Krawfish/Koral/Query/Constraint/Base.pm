package Krawfish::Koral::Query::Constraint::Base;
use Role::Tiny;
use strict;
use warnings;

requires qw/type to_string optimize min_span max_span/;

# Normalize the constraint (do nothing)
sub normalize {
  $_[0];
};


# Identify the constraint (do nothing)
sub identify {
  $_[0];
};


1;
