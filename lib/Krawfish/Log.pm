package Krawfish::Log;
use parent 'Exporter';
use strict;
use warnings;

our @EXPORT = 'print_log';

sub print_log {
  my $package = shift;
  printf "  >%10.10s | %s\n", $package, join(' ' ,@_);
};


1;
