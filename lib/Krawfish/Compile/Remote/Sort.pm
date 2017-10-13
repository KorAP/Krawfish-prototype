package Krawfish::Compile::Remote::Sort;
use Krawfish::Log;
use strict;
use warnings;

# Remotes have the structure
# [
#   ['https://foreign.node/api/v0.3', 'hjgscj32ngjcsngjsngcsj76t32'],
#   ['https://remote.korap/api/v0.3', 'ooxsxshjuFTEjhbt464768hgHJg']
# ]
# where the authorization header is passed from Kustvakt
#
# The connection is via WebSockets and each remote node
# returns the first x matches in a bunch only in form of sorting criteria
# for fast paging through results.
#
# After the results are returned, the results somehow should be validated
# to defend rogue nodes.

# The mechanism requires that the collation of the sorting is forwarded
# as well. This will override rank sorting on terms and fields
# (and is probably slow).

sub new {
  my $class = shift;
  bless {
    remote => shift,
    query => shift
  }, $class;
};


# Moive to next posting
sub next {
  ...
};

1;
