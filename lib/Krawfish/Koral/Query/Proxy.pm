package Krawfish::Koral::Query::Proxy;
use Role::Tiny;
use strict;
use warnings;

# Proxy all attributes from a single operand

sub is_anywhere {
  $_[0]->operand->is_anywhere;
};


sub is_optional {
  $_[0]->operand->is_optional;
};


sub is_null {
  $_[0]->operand->is_null;
};


sub is_negative {
  $_[0]->operand->is_negative;
};


sub is_extended {
  $_[0]->operand->is_extended;
};


sub is_extended_right {
  $_[0]->operand->is_extended_right;
};


sub is_extended_left {
  $_[0]->operand->is_extended_left;
};


sub maybe_unsorted {
  $_[0]->operand->maybe_unsorted;
};


sub is_classed {
  $_[0]->operand->is_classed;
};


sub min_span {
  $_[0]->operand->min_span;
};


sub max_span {
  $_[0]->operand->max_span;
};


1;
