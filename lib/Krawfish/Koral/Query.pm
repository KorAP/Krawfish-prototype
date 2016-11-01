package Krawfish::Koral::Query;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless \(my $self = ''), $class;
};

##########################
# Query Planning methods #
##########################

# Rewrite query to actual query
sub plan;

sub is_any            { 1 };
sub is_optional       { 0 };
sub is_null           { 0 };
sub is_negative       { 0 };
sub is_extended       { 0 };
sub is_extended_right { 0 };

sub maybe_anchor      {
  my $self = shift;
  return if $self->is_negative;
  return if $self->is_optional;
  return if $self->is_any;
  return 1;
};

# Check if the wrapped query may need to be sorted
# on focussing on a specific class.
# Normally spans are always sorted, but in case of
# a wrapped relation query, classed operands may
# be in arbitrary order. When focussing on these
# classes, the span has to me reordered.

sub maybe_unsorted { ... };

#############################
# Query Application methods #
#############################

# Deserialization of KoralQuery
sub from_koral {
  ...
};

# Overwritten
sub to_koral_fragment;

# Overwritten
sub to_string;


1;


__END__

