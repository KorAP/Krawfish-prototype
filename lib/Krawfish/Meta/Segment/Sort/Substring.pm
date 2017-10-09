package Krawfish::Meta::Segment::Sort::Substring;
use Krawfish::Log;
use strict;
use warnings;

warn 'NOT USED YET';

# To support C2-Wort-Type sorting based on word endings,
# It's necessary to support sorting based on substrings.
#
# EXAMPLE:
#   Sort based on the last two characters of a word in the
#   correct order: substring(-2,2)
#
#   match1: D[er] al[te] Ma[nn]
#   match2: D[er] gu[te] Schäf[er]
#
# This requires that all terms of a class are fetched from
# the dictionary (or at least X characters).
# Equal sequences will receive the same rank and can then be
# sorted alphabetically in the next run.
# Equal may mean that this is case insensitive.

sub new {
  my $class = shift;
  bless {
    offset  => shift, # Supports negative offset
    length  => shift,
    reverse => shift,  # The substring is read from right to left
    caseinsensitive => shift,
    resolve_diacritiques => shift
  }, $class;
};


1;
