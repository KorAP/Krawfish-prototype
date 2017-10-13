package Krawfish::Log;
use parent 'Exporter';
use strict;
use warnings;

# Simple log mechanism

our @EXPORT = 'print_log';

sub print_log {
  my $package = shift;
  foreach (@_) {
    foreach (split("\n", $_)) {
      printf "  >%10.10s | %s\n", $package, $_;
    };
  };
};


1;
