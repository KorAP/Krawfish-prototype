package Krawfish::Koral::Query::Constraint::InQuery;
use Role::Tiny::With;
use Krawfish::Koral::Query::Builder;
use strict;
use warnings;

with 'Krawfish::Koral::Query::Constraint::Base';

# Check that a query wraps two operands.
# This is relevant for C2 queries to check, e.g., if two
# words are in the same sentence.
# In the normalization phase the maxLength should be
# result in a InBetween query that can be joined.
# So before the query is actually checked it's checked
# if both operands are in a maxLength distance - otherwise
# it will fail.

# Constructor
sub new {
  my $class = shift;
  bless {
    query => shift
  }, $class;
};


1;
