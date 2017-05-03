package Krawfish::Result::Remote::Sort;
use Krawfish::Log;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless {

    # Remotes have the structure
    # [
    #   ['https://foreign.node/api/v0.3', 'hjgscj32ngjcsngjsngcsj76t32'],
    #   ['https://remote.korap/api/v0.3', 'ooxsxshjuFTEjhbt464768hgHJg']
    # ]
    # where the authorization header is passed from Kustvakt
    remote => shift,
    query => shift
  }, $class;
};

sub next;

1;
